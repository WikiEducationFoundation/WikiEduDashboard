#!/usr/bin/env ruby
# frozen_string_literal: true

# Harvests recent student revisions that added <ref> citations from a
# production dashboard course, emitting diff URLs in the forms that
# CheckRevisionClaims accepts. Output feeds end-to-end claim-verification
# runs and, eventually, the labeled eval datasets in
# fixtures/claim_verification_eval/.
#
# Pipeline (public APIs only, strictly sequential, paced):
#   1. <HOST>/courses/<slug>/course.json  — course window + home wiki
#   2. <HOST>/courses/<slug>/users.json   — student usernames
#   3. MediaWiki list=usercontribs        — mainspace edits in the window
#   4. MediaWiki action=compare           — keep revisions whose diff adds <ref>
#
# Usage:
#   COURSE='School/Title_(Term)' \
#     bundle exec ruby docs/analytics_scripts/claim_verification/harvest_reference_diffs.rb
#
# Env:
#   COURSE       — course slug(s), space-separated (required; slugs can
#                  contain commas, but never spaces)
#   HOST         — dashboard base URL (default https://dashboard.wikiedu.org)
#   MAX_DIFFS    — stop after this many ref-adding diffs in total (default 25)
#   PER_USER_CAP — max candidate revisions to diff-check per student (default 5)
#   MIN_BYTES    — minimum positive byte delta to consider (default 100)
#   SLEEP        — seconds to pause between HTTP requests (default 1.0)
#   OUT          — output JSONL path (default tmp/claim_verification_harvest/harvest.jsonl)

require 'net/http'
require 'json'
require 'uri'
require 'cgi'
require 'fileutils'
require 'nokogiri'

HOST = ENV.fetch('HOST', 'https://dashboard.wikiedu.org')
COURSES = ENV.fetch('COURSE') { abort 'COURSE env var is required (space-separated slugs)' }
            .split.map(&:strip)
MAX_DIFFS = ENV.fetch('MAX_DIFFS', '25').to_i
PER_USER_CAP = ENV.fetch('PER_USER_CAP', '5').to_i
MIN_BYTES = ENV.fetch('MIN_BYTES', '100').to_i
SLEEP_SECONDS = ENV.fetch('SLEEP', '1.0').to_f
OUT_PATH = ENV.fetch('OUT', 'tmp/claim_verification_harvest/harvest.jsonl')
USER_AGENT = 'WikiEdu-ClaimVerification-Harvest/1.0 (sage@wikiedu.org)'
STUDENT_ROLE = 0

def paced_get(url)
  sleep SLEEP_SECONDS
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  request['User-Agent'] = USER_AGENT
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end
  raise "HTTP #{response.code} for #{url}" unless response.code == '200'
  response.body
end

def get_json(url)
  JSON.parse(paced_get(url))
end

# Harvests ref-adding diffs from one course. Appends records to the shared
# output file and returns when the course is exhausted or the global cap is
# reached.
class CourseHarvester
  def initialize(slug, output, remaining_quota)
    @slug = slug
    @output = output
    @quota = remaining_quota
    @harvested = 0
    @checked = 0
  end

  attr_reader :harvested, :checked

  def run
    fetch_course
    return unless wikipedia_home_wiki?
    fetch_students
    puts "#{@slug}: #{@students.size} students, window #{@start}..#{@end}, wiki #{@api_host}"
    @students.each do |username|
      break if @harvested >= @quota
      harvest_user(username)
    end
  end

  private

  def fetch_course
    course = get_json("#{HOST}/courses/#{@slug}/course.json")['course']
    @start = course['start']
    @end = course['end']
    home_wiki = course['home_wiki'] || {}
    @language = home_wiki['language']
    @project = home_wiki['project']
    @api_host = "#{@language}.#{@project}.org"
  end

  def wikipedia_home_wiki?
    return true if @project == 'wikipedia'
    puts "#{@slug}: skipping — home wiki is #{@api_host}, not a Wikipedia"
    false
  end

  def fetch_students
    users = get_json("#{HOST}/courses/#{@slug}/users.json").dig('course', 'users') || []
    @students = users.select { |u| u['role'] == STUDENT_ROLE }.map { |u| u['username'] }
  end

  def harvest_user(username)
    candidates = contribs(username).select { |c| c['sizediff'].to_i >= MIN_BYTES }
    candidates.first(PER_USER_CAP).each do |contrib|
      break if @harvested >= @quota
      check_candidate(username, contrib)
    end
  end

  # One page of contribs (newest first) is plenty per student; the per-user
  # cap is far smaller than the page size.
  def contribs(username)
    params = {
      action: 'query', format: 'json', formatversion: 2,
      list: 'usercontribs', ucuser: username, ucnamespace: 0,
      ucprop: 'ids|title|timestamp|sizediff', uclimit: 50,
      ucstart: "#{@end[0, 10]}T23:59:59Z", ucend: "#{@start[0, 10]}T00:00:00Z"
    }
    query = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    response = get_json("https://#{@api_host}/w/api.php?#{query}")
    response.dig('query', 'usercontribs') || []
  rescue StandardError => e
    warn "  contribs failed for #{username}: #{e.message}"
    []
  end

  def check_candidate(username, contrib)
    @checked += 1
    refs_added = added_ref_count(contrib)
    return unless refs_added.positive?
    record = build_record(username, contrib, refs_added)
    @output.puts(record.to_json)
    @output.flush
    @harvested += 1
    puts "  + #{record[:diff_url]} (#{refs_added} refs, #{contrib['sizediff']} bytes)"
  end

  def added_ref_count(contrib)
    if contrib['parentid'].to_i.zero?
      count_refs(revision_wikitext(contrib['revid']))
    else
      diff_ref_delta(contrib['parentid'], contrib['revid'])
    end
  rescue StandardError => e
    warn "  diff check failed for rev #{contrib['revid']}: #{e.message}"
    0
  end

  # Net new <ref> tags: occurrences in added diff lines minus occurrences in
  # removed ones, so refs merely present in edited lines don't count.
  def diff_ref_delta(from_rev, to_rev)
    url = "https://#{@api_host}/w/api.php?action=compare&format=json&formatversion=2" \
          "&fromrev=#{from_rev}&torev=#{to_rev}"
    body = get_json(url).dig('compare', 'body') || ''
    doc = Nokogiri::HTML(body)
    count_refs(cell_text(doc, '.diff-addedline')) - count_refs(cell_text(doc, '.diff-deletedline'))
  end

  def cell_text(doc, selector)
    doc.css(selector).map(&:text).join("\n")
  end

  def revision_wikitext(rev_id)
    url = "https://#{@api_host}/w/api.php?action=query&format=json&formatversion=2" \
          "&prop=revisions&revids=#{rev_id}&rvprop=content&rvslots=main"
    get_json(url).dig('query', 'pages', 0, 'revisions', 0, 'slots', 'main', 'content') || ''
  end

  def count_refs(text)
    text.scan(/<ref[\s>]/).count
  end

  def build_record(username, contrib, refs_added)
    new_page = contrib['parentid'].to_i.zero?
    {
      course: @slug, username:, article: contrib['title'],
      rev_id: contrib['revid'], parent_id: contrib['parentid'],
      timestamp: contrib['timestamp'], sizediff: contrib['sizediff'],
      refs_added:, new_page:, diff_url: diff_url(contrib, new_page)
    }
  end

  def diff_url(contrib, new_page)
    title = CGI.escape(contrib['title'].tr(' ', '_'))
    if new_page
      "https://#{@api_host}/w/index.php?title=#{title}&diff=prev&oldid=#{contrib['revid']}"
    else
      "https://#{@api_host}/w/index.php?title=#{title}" \
        "&diff=#{contrib['revid']}&oldid=#{contrib['parentid']}"
    end
  end
end

FileUtils.mkdir_p(File.dirname(OUT_PATH))
total = 0
File.open(OUT_PATH, 'a') do |output|
  COURSES.each do |slug|
    break if total >= MAX_DIFFS
    harvester = CourseHarvester.new(slug, output, MAX_DIFFS - total)
    harvester.run
    total += harvester.harvested
    puts "#{slug}: kept #{harvester.harvested} of #{harvester.checked} diffs checked"
  end
end
puts "\n#{total} ref-adding diffs appended to #{OUT_PATH}"
