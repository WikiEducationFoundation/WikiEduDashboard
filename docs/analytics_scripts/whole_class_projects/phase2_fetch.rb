# frozen_string_literal: true

# Phase 2 of PLAN.md: fetch the Wikipedia data behind the quality signals.
#
# For every English Wikipedia course-article in wcp_analysis.comparison_set
# (tracked mainspace articles where the class added >= 200 characters),
# fetches and saves one bundle to data/phase2/bundles/<course>_<page>.json.gz:
#
# - revisions from 7 days before the course start to 180 days after the course
#   window ends (window = start - 7d .. end + 14d), with sha1 and tags for
#   revert detection, each flagged student / instructor / other
# - the revision before the first student edit (baseline), the last one in
#   the window (end), the last one 180 days after the window (f180, if that
#   date has passed) and the current one, with wikitext
# - LiftWing enwiki-articlequality predictions for baseline and end
#
# Existing bundles are skipped, so the script resumes where it stopped. Set
# WCP_SHARD=k/n to run n workers in parallel.
# Pages that no longer exist get a bundle with missing: true.
#
#   WCP_DB_USER=wiki WCP_DB_PASSWORD=wikiedu bundle exec ruby \
#     docs/analytics_scripts/whole_class_projects/phase2_fetch.rb

require 'json'
require 'time'
require 'net/http'
require 'zlib'
require 'fileutils'
require_relative 'wcp_common'

BUNDLE_DIR = File.expand_path('data/phase2/bundles', __dir__)
USER_AGENT = 'WikiEduDashboard-research/0.1 (https://dashboard.wikiedu.org; whole-class projects study)'
HOST = 'en.wikipedia.org'
LIFTWING = URI('https://api.wikimedia.org/service/lw/inference/v1/models/enwiki-articlequality:predict')
DAY = 86_400
FOLLOW_UP = 180 * DAY
MIN_CHARACTERS = 200

class Http
  attr_reader :requests

  def initialize
    @conns = {}
    @requests = 0
  end

  def get_json(host, params)
    uri = URI("https://#{host}/w/api.php")
    uri.query = URI.encode_www_form(params.merge(format: 'json', formatversion: 2))
    request(uri, Net::HTTP::Get.new(uri, 'User-Agent' => USER_AGENT))
  end

  def post_json(uri, body)
    req = Net::HTTP::Post.new(uri, 'User-Agent' => USER_AGENT, 'Content-Type' => 'application/json')
    req.body = JSON.generate(body)
    request(uri, req)
  end

  private

  def request(uri, req)
    attempts = 0
    begin
      attempts += 1
      @requests += 1
      sleep 0.1
      response = conn(uri.host).request(req)
      # Client errors other than rate limiting (e.g. LiftWing declining to
      # score a hidden revision) are recorded as missing values, not retried.
      return nil if response.code.start_with?('4') && response.code != '429'
      raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue StandardError
      @conns.delete(uri.host)
      raise if attempts >= 5

      sleep 2**attempts
      retry
    end
  end

  def conn(host)
    @conns[host] ||= Net::HTTP.start(host, 443, use_ssl: true, read_timeout: 90)
  end
end

class Phase2Fetch
  REV_PROPS = 'ids|timestamp|user|size|sha1|tags'

  def initialize
    @db = Wcp.client('wcp_analysis')
    @http = Http.new
    FileUtils.mkdir_p(BUNDLE_DIR)
  end

  def run
    rows = targets
    done = 0
    rows.each_with_index do |row, i|
      path = File.join(BUNDLE_DIR, "#{row['course_id']}_#{row['page_id']}.json.gz")
      next if File.exist?(path)

      next unless shard?(i)

      bundle = fetch(row)
      Zlib::GzipWriter.open("#{path}.tmp") { |gz| gz.write(JSON.generate(bundle)) }
      File.rename("#{path}.tmp", path)
      done += 1
      puts "#{i + 1}/#{rows.length} pages, #{@http.requests} requests" if (done % 100).zero?
    end
    puts "Done: #{rows.length} pages (#{done} fetched this run), #{@http.requests} requests"
  end

  private

  # WCP_SHARD=k/n processes only rows whose index % n == k, so several
  # workers can run side by side.
  def shard?(index)
    return true unless ENV['WCP_SHARD']

    k, n = ENV['WCP_SHARD'].split('/').map { |v| Integer(v) }
    index % n == k
  end

  def targets
    @db.query(<<~SQL).to_a
      SELECT DISTINCT ac.course_id, a.mw_page_id AS page_id, a.title, ac.character_sum,
             c.start, c.end
      FROM (SELECT DISTINCT course_id FROM comparison_set) s
      JOIN wcp_sanitized.articles_courses ac ON ac.course_id = s.course_id
      JOIN wcp_sanitized.articles a ON a.id = ac.article_id
      JOIN wcp_sanitized.wikis w ON w.id = a.wiki_id
      JOIN wcp_sanitized.courses c ON c.id = ac.course_id
      WHERE ac.tracked = 1 AND ac.character_sum >= #{MIN_CHARACTERS} AND a.namespace = 0
        AND w.language = 'en' AND w.project = 'wikipedia' AND a.mw_page_id IS NOT NULL
      ORDER BY ac.course_id, a.mw_page_id #{ENV["WCP_LIMIT"] ? "LIMIT #{Integer(ENV["WCP_LIMIT"])}" : ""}
    SQL
  end

  def roster(course_id)
    @rosters ||= {}
    @rosters[course_id] ||= @db.query(<<~SQL).each_with_object({}) do |row, acc|
      SELECT cu.role, u.username FROM wcp_sanitized.courses_users cu
      JOIN wcp_sanitized.users u ON u.id = cu.user_id
      WHERE cu.course_id = #{Integer(course_id)} AND cu.role IN (0, 1) AND u.username IS NOT NULL
    SQL
      acc[Wcp.normalize_username(row['username'])] = row['role'].zero? ? 'student' : 'instructor'
    end
  end

  def fetch(row)
    window_start = row['start'].to_i - (7 * DAY)
    window_end = row['end'].to_i + (14 * DAY)
    follow_end = [window_end + FOLLOW_UP, Time.now.to_i].min
    bundle = { course_id: row['course_id'], page_id: row['page_id'], dashboard_title: row['title'],
               character_sum: row['character_sum'], window_start: iso(window_start),
               window_end: iso(window_end), follow_up_end: iso(follow_end),
               f180_reached: window_end + FOLLOW_UP <= Time.now.to_i }
    before = query_revs(row['page_id'], rvdir: 'older', rvstart: iso(window_start), rvlimit: 1)
    return bundle.merge(missing: true) if before.nil?

    revs = all_revs(row['page_id'], window_start, follow_end)
    people = roster(row['course_id'])
    revs.each { |rev| rev['role'] = people.fetch(Wcp.normalize_username(rev['user'].to_s), 'other') }
    current = query_revs(row['page_id'], rvlimit: 1)
    bundle.merge(missing: false, title: before[:title], pre_window_rev: before[:revs].first,
                 revisions: revs, current_rev: current&.dig(:revs, 0))
          .then { |b| add_snapshots(b, window_end) }
  end

  def query_revs(page_id, params)
    response = @http.get_json(HOST, { action: 'query', prop: 'revisions', pageids: page_id,
                                      rvprop: 'ids|timestamp|user|size|sha1' }.merge(params))
    page = response&.dig('query', 'pages', 0)
    return nil if page.nil? || page['missing'] || page['invalid']

    { title: page['title'], revs: page['revisions'] || [] }
  end

  def all_revs(page_id, from, to)
    params = { action: 'query', prop: 'revisions', pageids: page_id, rvprop: REV_PROPS,
               rvdir: 'newer', rvstart: iso(from), rvend: iso(to), rvlimit: 'max' }
    revs = []
    loop do
      response = @http.get_json(HOST, params)
      break if response.nil?

      revs.concat(response.dig('query', 'pages', 0, 'revisions') || [])
      break unless response['continue']

      params = params.merge(response['continue'].transform_keys(&:to_sym))
    end
    revs
  end

  # baseline: parent of the first student revision (or the pre-window
  # revision); end: last revision in the window; f180: last revision by the
  # follow-up date; current: latest revision.
  def add_snapshots(bundle, window_end)
    revs = bundle[:revisions]
    first_student = revs.index { |rev| rev['role'] == 'student' }
    in_window = revs.select { |rev| Time.parse(rev['timestamp']).to_i <= window_end }
    baseline = if first_student&.positive? then revs[first_student - 1]
               elsif first_student&.zero? then bundle[:pre_window_rev]
               end
    snapshots = { 'baseline' => baseline, 'end' => in_window.last,
                  'f180' => (bundle[:f180_reached] ? revs.last : nil), 'current' => bundle[:current_rev] }
    snapshots.compact!
    contents = fetch_contents(snapshots.values.map { |rev| rev['revid'] }.uniq)
    bundle.merge(student_revisions: revs.count { |rev| rev['role'] == 'student' },
                 snapshots: snapshots.transform_values do |rev|
                   { revid: rev['revid'], timestamp: rev['timestamp'], text: contents[rev['revid']] }
                 end,
                 quality: %w[baseline end].to_h { |k| [k, snapshots[k] && quality(snapshots[k]['revid'])] })
  end

  def fetch_contents(revids)
    return {} if revids.empty?

    response = @http.get_json(HOST, action: 'query', prop: 'revisions', revids: revids.join('|'),
                                    rvprop: 'ids|content', rvslots: 'main')
    (response.dig('query', 'pages') || []).flat_map { |page| page['revisions'] || [] }
                                          .to_h { |rev| [rev['revid'], rev.dig('slots', 'main', 'content')] }
  end

  def quality(revid)
    response = @http.post_json(LIFTWING, { rev_id: revid })
    response&.dig('enwiki', 'scores', revid.to_s, 'articlequality', 'score')
  end

  def iso(time)
    Time.at(time).utc.iso8601
  end
end

$stdout.sync = true
Wcp.run_safely { Phase2Fetch.new.run }
