#!/usr/bin/env ruby
# frozen_string_literal: true

# Recon probe: estimate the in-window contribution profile of a course on
# outreachdashboard.wmflabs.org or dashboard.wikiedu.org without touching
# either dashboard's database. Use this to characterize a slow / stuck
# course update or to predict scale-of-work before kicking one off.
#
# Fetches course.json + users.json, then queries Wikimedia public APIs
# (`list=usercontribs`, `list=allimages`) per user and rolls counts up by
# cost axis:
#
#   non-wikidata revs (ns=0)  : ~4 s / rev   (ref-counter + lift-wing)
#   wikidata revs (any ns)    : ~0.2 s / rev (replica + diff analyzer)
#   Commons uploads           : 0.5 s (healthy) – 10 s (stalled) / upload
#
# Pure HTTP. No DB or dashboard internals touched.
#
# Required env: SLUG=<plain-slug>
# Optional env:
#   HOST            default https://outreachdashboard.wmflabs.org
#   WINDOW_START    default course.start (YYYY-MM-DD)
#   WINDOW_END      default min(course.end, today)
#   PER_USER_CAP    default 5000
#   USERS_LIMIT     limit users probed (for spot-check)

require 'date'
require 'json'
require 'net/http'
require 'uri'
require 'cgi'

SLUG_RAW = ENV.fetch('SLUG')
SLUG_ENC = URI.encode_www_form_component(SLUG_RAW).gsub('%2F', '/')
HOST     = ENV.fetch('HOST', 'https://outreachdashboard.wmflabs.org')
PER_USER_CAP = Integer(ENV.fetch('PER_USER_CAP', '5000'))
USERS_LIMIT  = ENV['USERS_LIMIT'] ? Integer(ENV['USERS_LIMIT']) : nil
USER_AGENT = 'WikiEdu-Dashboard-Recon/1.0 (sage@wikiedu.org)'

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

def api_get(endpoint, params)
  params = params.merge(format: 'json', formatversion: '2')
  uri = URI(endpoint)
  uri.query = URI.encode_www_form(params)
  req = Net::HTTP::Get.new(uri)
  req['User-Agent'] = USER_AGENT
  Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 60) do |http|
    res = http.request(req)
    raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  end
end

def wiki_endpoint(wiki)
  if wiki['project'] == 'wikidata'
    'https://www.wikidata.org/w/api.php'
  elsif wiki['project'] == 'commons'
    'https://commons.wikimedia.org/w/api.php'
  else
    "https://#{wiki['language']}.#{wiki['project']}.org/w/api.php"
  end
end

# Generic paginator: counts items at `items_path` until exhausted or PER_USER_CAP reached.
# Returns [count, capped_bool].
def paginated_count(endpoint, params, items_path)
  total = 0
  loop do
    j = api_get(endpoint, params)
    items = j.dig(*items_path) || []
    total += items.size
    return [total, true] if total >= PER_USER_CAP
    cont = j['continue']
    break unless cont
    params = params.merge(cont)
  end
  [total, false]
end

def count_usercontribs(endpoint, user, window_start, window_end, namespace: nil)
  params = { action: 'query', list: 'usercontribs', ucuser: user,
             ucstart: "#{window_end}T23:59:59Z", ucend: "#{window_start}T00:00:00Z",
             uclimit: 500, ucprop: 'ids|timestamp' }
  params[:ucnamespace] = namespace if namespace
  paginated_count(endpoint, params, %w[query usercontribs])
end

def count_commons_uploads(user, window_start, window_end)
  params = { action: 'query', list: 'allimages', aisort: 'timestamp', aidir: 'newer',
             aistart: "#{window_start}T00:00:00Z", aiend: "#{window_end}T23:59:59Z",
             aiuser: user, ailimit: 500, aiprop: 'timestamp' }
  paginated_count('https://commons.wikimedia.org/w/api.php', params, %w[query allimages])
end

# ---------- bootstrap ----------

course_url = "#{HOST}/courses/#{SLUG_ENC}/course.json"
users_url  = "#{HOST}/courses/#{SLUG_ENC}/users.json"
course = http_get_json(course_url).fetch('course')
users_payload = http_get_json(users_url)
users_arr = users_payload.dig('course', 'users') || users_payload.fetch('users', [])

home_wiki = course['home_wiki']
wikis     = course['wikis']
course_start = Date.parse(course['start']).to_s
course_end_raw = Date.parse(course['end']).to_s
today = Date.today.to_s
window_start = ENV.fetch('WINDOW_START', course_start)
window_end   = ENV.fetch('WINDOW_END', [course_end_raw, today].min)

# students + instructors (role 0/1)
candidates = users_arr.select { |u| [0, 1].include?(u['role']) }
usernames  = candidates.map { |u| u['username'].to_s.tr('_', ' ') }
usernames  = usernames.first(USERS_LIMIT) if USERS_LIMIT

puts "Course: #{course['slug']}"
puts "  home_wiki: #{home_wiki.inspect}"
puts "  wikis: #{wikis.inspect}"
puts "  course window: #{course_start} .. #{course_end_raw}"
puts "  probe window:  #{window_start} .. #{window_end}"
puts "  users (role 0/1): #{usernames.size}"
puts "  per_user_cap: #{PER_USER_CAP}"
puts

includes_wikidata = wikis.any? { |w| w['project'] == 'wikidata' }
non_wd_wikis = wikis.reject { |w| %w[wikidata commons].include?(w['project']) }

# Sum non-wikidata ns=0 contribs across the tracked wikis. Returns [count, any_capped].
def count_non_wd(non_wd_wikis, user, window_start, window_end)
  total = 0
  any_capped = false
  non_wd_wikis.each do |wiki|
    n, c = count_usercontribs(wiki_endpoint(wiki), user, window_start, window_end, namespace: 0)
    total += n
    any_capped ||= c
  end
  [total, any_capped]
end

# Probe one user across all relevant wikis. Returns a row hash.
def probe_user(user, non_wd_wikis, includes_wikidata, window_start, window_end)
  en_total, en_capped = count_non_wd(non_wd_wikis, user, window_start, window_end)
  wd_total, wd_capped = includes_wikidata ?
                          count_usercontribs('https://www.wikidata.org/w/api.php',
                                             user, window_start, window_end) :
                          [0, false]
  # Always count Commons uploads — UploadImporter touches them even when
  # Commons isn't a tracked wiki.
  up_total, up_capped = count_commons_uploads(user, window_start, window_end)
  { user: user, non_wd_ns0: en_total, non_wd_capped: en_capped,
    wikidata: wd_total, wikidata_capped: wd_capped,
    commons_uploads: up_total, commons_uploads_capped: up_capped }
end

per_user = []
totals = Hash.new(0)
capped = Hash.new(0)

usernames.each_with_index do |user, i|
  print format("[%3d/%d] %-30s ", i + 1, usernames.size, user[0, 28])
  $stdout.flush
  begin
    row = probe_user(user, non_wd_wikis, includes_wikidata, window_start, window_end)
    totals[:non_wd_ns0]      += row[:non_wd_ns0]
    totals[:wikidata]        += row[:wikidata]
    totals[:commons_uploads] += row[:commons_uploads]
    capped[:non_wd]   += 1 if row[:non_wd_capped]
    capped[:wikidata] += 1 if row[:wikidata_capped]
    capped[:uploads]  += 1 if row[:commons_uploads_capped]
    puts format('non_wd_ns0=%-6d  wd=%-6d  up=%-6d %s%s%s',
                row[:non_wd_ns0], row[:wikidata], row[:commons_uploads],
                row[:non_wd_capped] ? '!' : ' ',
                row[:wikidata_capped] ? '!' : ' ',
                row[:commons_uploads_capped] ? '!' : ' ')
  rescue StandardError => e
    row = { user: user, error: e.message }
    puts "ERROR #{e.class}: #{e.message}"
  end
  per_user << row
end

CAP_KEYS = {
  non_wd_ns0: :non_wd_capped,
  wikidata: :wikidata_capped,
  commons_uploads: :commons_uploads_capped
}.freeze

puts
puts '=== Top contributors by axis ==='
top = ->(key) { per_user.reject { |r| r[:error] }.sort_by { |r| -r[key].to_i }.first(10) }
%i[non_wd_ns0 wikidata commons_uploads].each do |k|
  puts "-- #{k} --"
  top.call(k).each do |r|
    suffix = r[CAP_KEYS[k]] ? ' (capped)' : ''
    puts format('  %-30s %d%s', r[:user], r[k], suffix)
  end
end

puts
puts '=== Totals ==='
puts format('  non-wikidata ns=0 revs : %d  (capped: %d)', totals[:non_wd_ns0], capped[:non_wd])
puts format('  wikidata revs          : %d  (capped: %d)', totals[:wikidata], capped[:wikidata])
puts format('  Commons uploads        : %d  (capped: %d)',
            totals[:commons_uploads], capped[:uploads])

puts
puts '=== Cost projection (per 2026-04-24 benchmark) ==='
non_wd_cost = totals[:non_wd_ns0] * 4.0
wd_cost     = totals[:wikidata]   * 0.2
upload_low  = totals[:commons_uploads] * 0.5
upload_high = totals[:commons_uploads] * 10.0
total_low   = non_wd_cost + wd_cost + upload_low
total_high  = non_wd_cost + wd_cost + upload_high
puts format('  non-wikidata: %d revs * 4 s    = %d s', totals[:non_wd_ns0], non_wd_cost)
puts format('  wikidata:     %d revs * 0.2 s  = %d s', totals[:wikidata],   wd_cost)
puts format('  uploads (low):  %d * 0.5 s    = %d s', totals[:commons_uploads], upload_low)
puts format('  uploads (high): %d * 10 s     = %d s', totals[:commons_uploads], upload_high)
puts format('  Projected total (low) : %.1f s = %.2f h', total_low, total_low / 3600.0)
puts format('  Projected total (high): %.1f s = %.2f h', total_high, total_high / 3600.0)
