# frozen_string_literal: true

# Phase 1 of PLAN.md: verify collaboration mode from Wikipedia page histories.
#
# For every course in wcp_analysis.course_mode_labels, takes candidate shared
# articles — the top 3 assigned articles, the top 3 edited mainspace articles
# by characters, and any shared_articles the LLM label named — and fetches each
# page's revisions from 7 days before the course start to 14 days after its
# end from the public MediaWiki API. Pages are fetched by page id where known,
# so later moves (draft to mainspace, renames) are followed.
#
# Writes:
#   wcp_analysis.page_history_stats  one row per course x article
#   data/phase1_revisions.jsonl      every in-window revision, flagged by
#                                    whether its author is an enrolled
#                                    student or instructor (used in Phase 2)
# API responses are cached in data/cache/revisions/.
#
# Limitation: work drafted in sandboxes and moved in one edit shows up as a
# single editor on the live page.
#
#   WCP_DB_USER=wiki WCP_DB_PASSWORD=wikiedu bundle exec ruby \
#     docs/analytics_scripts/whole_class_projects/phase1_page_histories.rb

require 'json'
require 'net/http'
require 'digest'
require 'fileutils'
require_relative 'wcp_common'

DATA_DIR = File.expand_path('data', __dir__)
CACHE_DIR = File.join(DATA_DIR, 'cache/revisions')
REVISIONS_OUT = File.join(DATA_DIR, 'phase1_revisions.jsonl')
USER_AGENT = 'WikiEduDashboard-research/0.1 (https://dashboard.wikiedu.org; whole-class projects study)'
WINDOW_BEFORE = 7 * 86_400
WINDOW_AFTER = 14 * 86_400
TOP_N = 3

class MediaWiki
  def initialize
    FileUtils.mkdir_p(CACHE_DIR)
    @http = {}
    @requests = 0
  end

  attr_reader :requests

  # Revisions in [from, to] plus the last revision before from (baseline size).
  def revisions(host, page, from, to)
    key = Digest::SHA256.hexdigest([host, page, from, to].to_json)[0, 32]
    path = File.join(CACHE_DIR, "#{key}.json")
    return JSON.parse(File.read(path)) if File.exist?(path)

    result = fetch_revisions(host, page, from, to)
    File.write(path, JSON.generate(result))
    result
  end

  private

  def page_params(page)
    page[:page_id] ? { pageids: page[:page_id] } : { titles: page[:title] }
  end

  def fetch_revisions(host, page, from, to)
    base = { action: 'query', format: 'json', formatversion: 2, prop: 'revisions',
             rvprop: 'ids|timestamp|user|size' }.merge(page_params(page))
    before = get(host, base.merge(rvdir: 'older', rvstart: iso(from), rvlimit: 1))
    info = before.dig('query', 'pages', 0) || {}
    return { 'missing' => true } if info['missing'] || info['invalid']

    revs = []
    params = base.merge(rvdir: 'newer', rvstart: iso(from), rvend: iso(to), rvlimit: 'max')
    loop do
      response = get(host, params)
      revs.concat(response.dig('query', 'pages', 0, 'revisions') || [])
      break unless response['continue']

      params = params.merge(response['continue'].transform_keys(&:to_sym))
    end
    { 'page_id' => info['pageid'], 'title' => info['title'], 'namespace' => info['ns'],
      'baseline' => info.dig('revisions', 0), 'revisions' => revs }
  end

  def get(host, params)
    uri = URI("https://#{host}/w/api.php")
    uri.query = URI.encode_www_form(params)
    attempts = 0
    begin
      attempts += 1
      @requests += 1
      sleep 0.1
      response = connection(host).request(Net::HTTP::Get.new(uri, 'User-Agent' => USER_AGENT))
      raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue StandardError
      @http.delete(host)
      raise if attempts >= 4

      sleep 2**attempts
      retry
    end
  end

  def connection(host)
    @http[host] ||= Net::HTTP.start(host, 443, use_ssl: true, read_timeout: 60)
  end

  def iso(time)
    Time.at(time).utc.iso8601
  end
end

class PageHistories
  def initialize
    @db = Wcp.client('wcp_analysis')
    @api = MediaWiki.new
  end

  def run
    courses = @db.query(<<~SQL).to_a
      SELECT l.course_id, l.shared_articles, c.start, c.end, c.home_wiki_id
      FROM course_mode_labels l JOIN wcp_sanitized.courses c ON c.id = l.course_id
      ORDER BY l.course_id #{ENV['WCP_LIMIT'] ? "LIMIT #{Integer(ENV['WCP_LIMIT'])}" : ''}
    SQL
    @hosts = wiki_hosts
    stats = []
    File.open(REVISIONS_OUT, 'w') do |out|
      courses.each_with_index do |course, i|
        stats.concat(course_stats(course, out))
        puts "#{i + 1}/#{courses.length} courses, #{@api.requests} API requests" if ((i + 1) % 50).zero?
      end
    end
    write_stats(stats)
    puts "Done: #{stats.length} course-article rows, #{@api.requests} API requests"
  end

  private

  SPECIAL_HOSTS = { 'wikidata' => 'www.wikidata.org', 'commons' => 'commons.wikimedia.org',
                    'species' => 'species.wikimedia.org' }.freeze

  def wiki_hosts
    @db.query('SELECT id, language, project FROM wcp_sanitized.wikis').to_h do |row|
      [row['id'], SPECIAL_HOSTS[row['project']] || "#{row['language']}.#{row['project']}.org"]
    end
  end

  def people(course_id)
    rows = @db.query(<<~SQL)
      SELECT cu.role, u.username FROM wcp_sanitized.courses_users cu
      JOIN wcp_sanitized.users u ON u.id = cu.user_id
      WHERE cu.course_id = #{Integer(course_id)} AND cu.role IN (0, 1)
    SQL
    rows.each_with_object({ 0 => Set.new, 1 => Set.new }) do |row, acc|
      acc[row['role']] << Wcp.normalize_username(row['username']) if row['username']
    end
  end

  def candidates(course)
    id = Integer(course['course_id'])
    assigned = @db.query(<<~SQL).to_a
      SELECT a.mw_page_id AS page_id, COALESCE(a.wiki_id, s.wiki_id) AS wiki_id,
             COALESCE(a.title, s.article_title) AS title, COUNT(DISTINCT s.user_id) AS n
      FROM wcp_sanitized.assignments s
      JOIN wcp_sanitized.courses_users cu ON cu.course_id = s.course_id AND cu.user_id = s.user_id AND cu.role = 0
      LEFT JOIN wcp_sanitized.articles a ON a.id = s.article_id
      WHERE s.course_id = #{id} AND s.role = 0 AND (a.id IS NULL OR a.namespace IN (0, 118))
      GROUP BY page_id, wiki_id, title ORDER BY n DESC LIMIT #{TOP_N}
    SQL
    edited = @db.query(<<~SQL).to_a
      SELECT a.mw_page_id AS page_id, a.wiki_id, a.title FROM wcp_sanitized.articles_courses ac
      JOIN wcp_sanitized.articles a ON a.id = ac.article_id
      WHERE ac.course_id = #{id} AND ac.tracked = 1 AND ac.character_sum > 0 AND a.namespace = 0
      ORDER BY ac.character_sum DESC LIMIT #{TOP_N}
    SQL
    named = JSON.parse(course['shared_articles'] || '[]').map do |title|
      { 'page_id' => nil, 'wiki_id' => course['home_wiki_id'], 'title' => title }
    end
    tag(assigned, 'assigned') + tag(edited, 'edited') + tag(named, 'llm_named')
  end

  def tag(rows, source)
    rows.map { |row| row.merge('source' => source) }
  end

  def course_stats(course, out)
    return [] unless course['start'] && course['end']

    from = course['start'].to_i - WINDOW_BEFORE
    to = course['end'].to_i + WINDOW_AFTER
    roster = people(course['course_id'])
    fetched = {}
    merge_candidates(candidates(course)).each do |cand|
      host = @hosts[cand['wiki_id']] || 'en.wikipedia.org'
      page = { page_id: cand['page_id'], title: cand['title']&.tr('_', ' ') }
      next if page[:page_id].nil? && page[:title].to_s.empty?

      history = @api.revisions(host, page, from, to)
      key = history['missing'] ? [host, :missing, page] : [host, history['page_id']]
      if fetched[key]
        fetched[key][:source] = [fetched[key][:source], cand['source']].uniq.join('+')
      else
        fetched[key] = summarize(course, cand, host, history, roster, out)
      end
    end
    fetched.values
  end

  # One row per page: the same article can come from several sources.
  def merge_candidates(cands)
    cands.group_by { |c| c['page_id'] ? "p#{c['wiki_id']}:#{c['page_id']}" : "t#{c['wiki_id']}:#{c['title'].to_s.tr('_', ' ').downcase}" }
         .map { |_key, group| group.first.merge('source' => group.map { |c| c['source'] }.uniq.join('+')) }
  end

  def summarize(course, cand, host, history, roster, out)
    base = { course_id: course['course_id'], wiki: host, source: cand['source'],
             requested_title: cand['title'], requested_page_id: cand['page_id'] }
    return base.merge(missing: true) if history['missing']

    prev_size = history.dig('baseline', 'size') || 0
    tally = Hash.new(0)
    editors = Set.new
    students = Set.new
    instructors = Set.new
    history['revisions'].each do |rev|
      user = Wcp.normalize_username(rev['user'].to_s)
      delta = rev['size'].to_i - prev_size
      prev_size = rev['size'].to_i
      role = if roster[0].include?(user) then 'student'
             elsif roster[1].include?(user) then 'instructor'
             else 'other'
             end
      editors << user
      students << user if role == 'student'
      instructors << user if role == 'instructor'
      tally["#{role}_revs"] += 1
      tally["#{role}_bytes_added"] += delta if delta.positive?
      out.puts(JSON.generate(course_id: course['course_id'], wiki: host, page_id: history['page_id'],
                             rev_id: rev['revid'], parent_id: rev['parentid'], user: rev['user'],
                             timestamp: rev['timestamp'], size: rev['size'], delta:, role:))
    end
    base.merge(missing: false, page_id: history['page_id'], title: history['title'],
               namespace: history['namespace'], baseline_size: history.dig('baseline', 'size'),
               revs: history['revisions'].length, editors: editors.size,
               student_editors: students.size, instructor_editors: instructors.size,
               enrolled_students: roster[0].size,
               student_revs: tally['student_revs'], instructor_revs: tally['instructor_revs'],
               other_revs: tally['other_revs'], student_bytes_added: tally['student_bytes_added'],
               instructor_bytes_added: tally['instructor_bytes_added'],
               other_bytes_added: tally['other_bytes_added'])
  end

  COLUMNS = {
    course_id: 'INT', wiki: 'VARCHAR(64)', source: 'VARCHAR(40)', requested_title: 'VARCHAR(512)',
    requested_page_id: 'INT', missing: 'BOOLEAN', page_id: 'INT', title: 'VARCHAR(512)',
    namespace: 'INT', baseline_size: 'INT', revs: 'INT', editors: 'INT', student_editors: 'INT',
    instructor_editors: 'INT', enrolled_students: 'INT', student_revs: 'INT', instructor_revs: 'INT',
    other_revs: 'INT', student_bytes_added: 'INT', instructor_bytes_added: 'INT',
    other_bytes_added: 'INT'
  }.freeze

  def write_stats(stats)
    @db.query('DROP TABLE IF EXISTS page_history_stats')
    @db.query("CREATE TABLE page_history_stats (#{COLUMNS.map { |c, t| "`#{c}` #{t}" }.join(', ')}, " \
              'INDEX (course_id))')
    statement = @db.prepare("INSERT INTO page_history_stats VALUES (#{(['?'] * COLUMNS.size).join(', ')})")
    @db.query('START TRANSACTION')
    stats.each do |row|
      statement.execute(*COLUMNS.keys.map { |c| [true, false].include?(row[c]) ? (row[c] ? 1 : 0) : row[c] })
    end
    @db.query('COMMIT')
  end
end

Wcp.run_safely { PageHistories.new.run }
