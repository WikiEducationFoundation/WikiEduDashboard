#!/usr/bin/env ruby
# frozen_string_literal: true

# Recon probe for the "dormant course, far-future end date" update-cost shape.
#
# In the timeslice update system, each update re-scans every daily timeslice
# from the ingestion high-water mark (the timeslice containing the latest
# tracked student revision — TimesliceManager#get_ingestion_start_time_for_wiki)
# up to today, one replica-revision-tools HTTP query per wiki-timeslice.
# Empty timeslices never advance the watermark, so a course whose students
# stopped editing years ago but whose end date is far in the future re-scans
# the whole gap on every single update, forever.
#
# This probe reproduces the updater's own query (revisions.php on
# replica-revision-tools.wmcloud.org, students only) to find the per-wiki
# watermark, computes the expected timeslice-scan count, measures per-query
# latency, and projects update runtime. Compare the expected count with
# `processed` in course.json's flags.update_logs — an exact-ish match
# confirms the empty-timeslice-scan diagnosis (small excess = split slices).
#
# Pure HTTP. No DB or dashboard internals touched.
#
# Required env: SLUG=<plain-slug>
# Optional env:
#   HOST            default https://outreachdashboard.wmflabs.org
#   LATENCY_SAMPLES default 3 (empty-day timing queries per wiki)

require 'date'
require 'time'
require 'json'
require 'net/http'
require 'uri'

SLUG_RAW = ENV.fetch('SLUG')
SLUG_ENC = URI.encode_www_form_component(SLUG_RAW).gsub('%2F', '/')
HOST     = ENV.fetch('HOST', 'https://outreachdashboard.wmflabs.org')
LATENCY_SAMPLES = Integer(ENV.fetch('LATENCY_SAMPLES', '3'))
USER_AGENT = 'WikiEdu-Dashboard-Recon/1.0 (sage@wikiedu.org)'
REPLICA_URL = 'https://replica-revision-tools.wmcloud.org/revisions.php'
TIMESLICE_SECONDS = 86_400
USER_CHUNK = 40 # keep GET URLs a manageable length

def http_get_json(url)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  req['User-Agent'] = USER_AGENT
  Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 60) do |http|
    res = http.request(req)
    raise "HTTP #{res.code} for #{url}" unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  end
end

# Mirrors Replica::SPECIAL_DB_NAMES / #project_database_params. course.json
# wikis come as {language, project}.
def replica_db_params(wiki)
  language = wiki['language']
  project  = wiki['project']
  return { 'db' => 'wikidatawiki' } if project == 'wikidata'
  return { 'db' => 'commonswiki' }  if language == 'commons' && project == 'wikimedia'
  return { 'db' => 'metawiki' }     if language == 'meta' && project == 'wikimedia'
  return { 'db' => 'incubatorwiki' } if language == 'incubator' && project == 'wikimedia'
  return { 'db' => 'sourceswiki' }  if language.nil? && project == 'wikisource'
  { 'lang' => language.tr('-', '_'), 'project' => project }
end

def replica_query_uri(db_params, usernames, start_ts, end_ts)
  params = db_params.to_a +
           usernames.map { |u| ['usernames[]', u] } +
           [['start', start_ts], ['end', end_ts]]
  uri = URI(REPLICA_URL)
  uri.query = URI.encode_www_form(params)
  uri
end

def timed_http_get(uri)
  req = Net::HTTP::Get.new(uri)
  req['User-Agent'] = USER_AGENT
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  body = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                         open_timeout: 10, read_timeout: 120) do |http|
    res = http.request(req)
    raise "Replica HTTP #{res.code}: #{res.body[0, 200]}" unless res.is_a?(Net::HTTPSuccess)
    res.body
  end
  [body, Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0]
end

# One revisions.php query, exactly as the updater issues it (modulo chunking).
# Returns [rev_timestamps, seconds_elapsed].
def replica_revisions(db_params, usernames, start_ts, end_ts)
  body, elapsed = timed_http_get(replica_query_uri(db_params, usernames, start_ts, end_ts))
  parsed = JSON.parse(body)
  raise "Replica error: #{parsed['error']}" if parsed.is_a?(Hash) && parsed['success'] == false
  data = parsed.is_a?(Hash) ? parsed.fetch('data', []) : parsed
  [data.map { |r| r['rev_timestamp'] }.compact, elapsed]
end

# Latest tracked student revision timestamp on one wiki over the whole
# course window (the ingestion watermark), plus the total tracked-rev count.
def find_watermark(db_params, students, course_start, now)
  timestamps = []
  students.each_slice(USER_CHUNK) do |chunk|
    ts, = replica_revisions(db_params, chunk, mw_ts(course_start), mw_ts(now))
    timestamps.concat(ts)
    sleep 0.5
  end
  [timestamps.max, timestamps.size]
end

# Average latency of an empty(ish)-day revisions.php query — the per-timeslice
# unit cost of the scan.
def sample_latency(db_params, students, now)
  latencies = Array.new(LATENCY_SAMPLES) do |i|
    day_start = now - ((i + 2) * TIMESLICE_SECONDS)
    _, secs = replica_revisions(db_params, students.first(USER_CHUNK),
                                mw_ts(day_start), mw_ts(day_start + TIMESLICE_SECONDS))
    sleep 0.5
    secs
  end
  latencies.sum / latencies.size
end

def mw_ts(time)
  time.utc.strftime('%Y%m%d%H%M%S')
end

# ---------- bootstrap ----------

course = http_get_json("#{HOST}/courses/#{SLUG_ENC}/course.json").fetch('course')
users_payload = http_get_json("#{HOST}/courses/#{SLUG_ENC}/users.json")
users_arr = users_payload.dig('course', 'users') || users_payload.fetch('users', [])

# CourseRevisionUpdater fetches revisions for course.students only (role 0).
students = users_arr.select { |u| u['role'].zero? }
             .map { |u| u['username'].to_s.tr('_', ' ') }
course_start = Time.parse(course.fetch('start'))
course_end   = Time.parse(course.fetch('end'))
now = Time.now.utc
flags = course['flags'] || {}
update_logs = (flags['update_logs'] || {}).values
last_log = update_logs.max_by { |l| l['start_time'].to_s }
avg_delay = course.dig('updates', 'average_delay')

slice_index = ->(time) { ((time - course_start) / TIMESLICE_SECONDS).floor }
today_index = slice_index.call([now, course_end].min)

puts "Course: #{course['slug']}"
puts "  window: #{course_start.utc} .. #{course_end.utc} (#{course['ended'] ? 'ended' : 'ongoing'})"
puts "  students (role 0): #{students.size}"
puts "  dashboard edit_count: #{course['edit_count'].inspect}"
if last_log
  dur = (Time.parse(last_log['end_time']) - Time.parse(last_log['start_time'])).round
  puts "  last update: #{last_log['start_time']}  #{dur} s, " \
       "processed=#{last_log['processed']} reprocessed=#{last_log['reprocessed']}"
end
puts "  average_delay between updates: #{avg_delay} s" if avg_delay
puts

expected_total = 0
per_wiki = []

course.fetch('wikis').each do |wiki|
  label = "#{wiki['language'] || 'www'}.#{wiki['project']}"
  db_params = replica_db_params(wiki)

  last_edit, rev_count = find_watermark(db_params, students, course_start, now)
  pin_time = last_edit ? Time.parse("#{last_edit}Z") : course_start
  slices = today_index - slice_index.call(pin_time) + 1
  avg_latency = sample_latency(db_params, students, now)

  expected_total += slices
  per_wiki << { label:, slices:, avg_latency: }
  puts format('%-25s tracked revs: %-6d last: %-16s scan window: %d timeslices  ' \
              '(~%.2f s/query)',
              label, rev_count, last_edit || 'NEVER', slices, avg_latency)
  puts '  ^ no student ever edited this wiki: full-history scan every update' unless last_edit
end

puts
puts '=== Projection ==='
http_secs = per_wiki.sum { |w| w[:slices] * w[:avg_latency] }
puts format('  expected timeslice scans/update : %d (+%d per day)',
            expected_total, per_wiki.size)
puts format('  raw HTTP time                   : %.0f s = %.1f min', http_secs, http_secs / 60.0)
# Overhead calibrated against course 10781 on 2026-08-20: observed 1373 s
# vs 1013 s raw HTTP for 3867 slices (~35% Rails-side work per slice).
puts format('  with ~35%% Rails-side overhead   : %.1f min', http_secs * 1.35 / 60.0)
if last_log && last_log['processed']
  delta = last_log['processed'] - expected_total
  puts format('  observed processed count        : %d (delta %+d — small positive excess ' \
              'is split timeslices)', last_log['processed'], delta)
end
if avg_delay&.positive?
  updates_per_day = 86_400.0 / avg_delay
  puts format('  worker time burned per day      : %.1f updates x %.1f min = %.1f h',
              updates_per_day, http_secs * 1.35 / 60.0,
              updates_per_day * http_secs * 1.35 / 3600.0)
end
