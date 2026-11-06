#!/usr/bin/env ruby
# frozen_string_literal: true

# Estimate UpdateCourseStats wall-time cost for a course (or a list of courses)
# via public Wikimedia + dashboard APIs, and find a date window that lands
# within a target time range. Pure HTTP — no dashboard DB or rails needed.
#
# Use this to find good benchmarking candidates without running real updates,
# or to narrow a known-slow course's date window so a benchmark fits a budget.
#
# Two modes:
#
#   # 1) Single course: probe the full course window, then suggest a narrowed
#   #    window targeting TARGET_MIN..TARGET_MAX seconds.
#   SLUG='Some/Course_slug' bundle exec ruby benchmarks/estimate_update_cost.rb
#
#   # 2) Multiple courses: resolve IDs via /find_course, probe each, and
#   #    rank by which best fits the target. Useful for screening the
#   #    long_update queue.
#   IDS='12,34,56' bundle exec ruby benchmarks/estimate_update_cost.rb
#
# Env:
#   SLUG=...               — single-course mode
#   IDS=12,34,56           — multi-course mode (resolved via /find_course/:id)
#   HOST=...               — dashboard host (default outreachdashboard.wmflabs.org)
#   TARGET_MIN=300         — desired estimate floor in seconds
#   TARGET_MAX=600         — desired estimate ceiling in seconds
#   PROBE_DAYS=14          — calibration window for fast estimates (default 14)
#                             0 = always probe the full course window (slower
#                             but more accurate for sparse courses)
#   PER_USER_CAP=5000      — max contribs counted per user per wiki
#   USERS_LIMIT=N          — sample only the first N users (faster, less accurate)
#
# Cost coefficients (from prior benchmark runs; see probe_course_contributions.rb):
#   non-wikidata revs (ns=0)  ~4.0  s/rev   (ref-counter + lift-wing)
#   wikidata revs              ~0.2  s/rev  (replica + diff analyzer)
#   Commons uploads            ~0.8  s/upload (median; can stall to ~10s)

require 'date'
require 'json'
require 'net/http'
require 'uri'

HOST          = ENV.fetch('HOST', 'https://outreachdashboard.wmflabs.org')
TARGET_MIN    = Integer(ENV.fetch('TARGET_MIN', '300'))
TARGET_MAX    = Integer(ENV.fetch('TARGET_MAX', '600'))
PROBE_DAYS    = Integer(ENV.fetch('PROBE_DAYS', '14'))
PER_USER_CAP  = Integer(ENV.fetch('PER_USER_CAP', '5000'))
USERS_LIMIT   = ENV['USERS_LIMIT'] ? Integer(ENV['USERS_LIMIT']) : nil
USER_AGENT    = 'WikiEdu-Dashboard-Estimator/1.0 ' \
                '(https://github.com/WikiEducationFoundation/WikiEduDashboard)'

COST_NON_WD_REV     = 4.0
COST_WIKIDATA_REV   = 0.2
COST_COMMONS_UPLOAD = 0.8

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

def http_head_location(url)
  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
    res = http.request(Net::HTTP::Head.new(uri.request_uri, 'User-Agent' => USER_AGENT))
    res.is_a?(Net::HTTPRedirection) ? res['location'] : nil
  end
end

def slug_from_id(id)
  loc = http_head_location("#{HOST}/find_course/#{id}")
  loc&.sub(%r{^.*/courses/}, '')
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
  case wiki['project']
  when 'wikidata' then 'https://www.wikidata.org/w/api.php'
  when 'commons'  then 'https://commons.wikimedia.org/w/api.php'
  else "https://#{wiki['language']}.#{wiki['project']}.org/w/api.php"
  end
end

# Paginated count of items at items_path. Returns [count, capped?].
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

# Probe a date window for one course: per-axis totals across all users.
# Returns { non_wd:, wikidata:, uploads:, capped: }.
def probe_window(course, users, window_start, window_end)
  non_wd = course['wikis'].reject { |w| %w[wikidata commons].include?(w['project']) }
  has_wd = course['wikis'].any? { |w| w['project'] == 'wikidata' }
  totals = { non_wd: 0, wikidata: 0, uploads: 0 }
  capped = { non_wd: 0, wikidata: 0, uploads: 0 }
  users.each do |u|
    accumulate_user(totals, capped, u, non_wd, has_wd, window_start, window_end)
  end
  totals.merge(capped: capped)
end

def accumulate_user(totals, capped, user, non_wd_wikis, has_wd, w_start, w_end)
  non_wd_wikis.each do |wiki|
    n, c = count_usercontribs(wiki_endpoint(wiki), user, w_start, w_end, namespace: 0)
    totals[:non_wd] += n
    capped[:non_wd] += 1 if c
  end
  if has_wd
    n, c = count_usercontribs('https://www.wikidata.org/w/api.php', user, w_start, w_end)
    totals[:wikidata] += n
    capped[:wikidata] += 1 if c
  end
  n, c = count_commons_uploads(user, w_start, w_end)
  totals[:uploads] += n
  capped[:uploads] += 1 if c
end

def cost_for(totals)
  totals[:non_wd] * COST_NON_WD_REV +
    totals[:wikidata] * COST_WIKIDATA_REV +
    totals[:uploads] * COST_COMMONS_UPLOAD
end

# Linearly extrapolate from a calibration probe to a target cost.
# Returns the suggested window-size in days, or nil if calibration probe was empty.
def days_for_target(probe_totals, probe_days, target_cost)
  probe_cost = cost_for(probe_totals)
  return nil if probe_cost.zero?
  rate = probe_cost.to_f / probe_days # cost per day
  (target_cost / rate).ceil.clamp(1, 10_000)
end

def load_course(slug)
  enc = URI.encode_www_form_component(slug).gsub('%2F', '/')
  course = http_get_json("#{HOST}/courses/#{enc}/course.json").fetch('course')
  users_payload = http_get_json("#{HOST}/courses/#{enc}/users.json")
  users_arr = users_payload.dig('course', 'users') || users_payload.fetch('users', [])
  candidates = users_arr.select { |u| [0, 1].include?(u['role']) }
  usernames = candidates.map { |u| u['username'].to_s.tr('_', ' ') }
  usernames = usernames.first(USERS_LIMIT) if USERS_LIMIT
  [course, usernames]
end

def fmt_cost(seconds)
  if seconds < 90
    format('%ds', seconds)
  elsif seconds < 5400
    format('%.1fm', seconds / 60.0)
  else
    format('%.1fh', seconds / 3600.0)
  end
end

# Effective course window: course.start to min(course.end, today).
def course_window(course)
  cs = Date.parse(course['start'])
  ce = [Date.parse(course['end']), Date.today].min
  [cs, ce, (ce - cs).to_i + 1]
end

# Calibration window — last PROBE_DAYS days, or full course if smaller / disabled.
def calibration_window(course_start, course_end, course_days)
  return [course_start, course_end, course_days] if PROBE_DAYS.zero? || PROBE_DAYS >= course_days
  [course_end - (PROBE_DAYS - 1), course_end, PROBE_DAYS]
end

def suggest_window(probe, probe_days, course_start, course_end, course_days, full_cost)
  target_days = days_for_target(probe, probe_days, TARGET_MAX)
  return nil if target_days.nil?
  return { start: course_start, end: course_end, days: course_days, estimate_s: full_cost } \
    if target_days >= course_days
  { start: course_end - (target_days - 1), end: course_end, days: target_days,
    estimate_s: cost_for(probe) * (target_days.to_f / probe_days) }
end

# Estimate cost for a course and recommend a window. Returns a hash.
def estimate_for_course(slug)
  course, users = load_course(slug)
  c_start, c_end, c_days = course_window(course)
  p_start, p_end, p_days = calibration_window(c_start, c_end, c_days)
  probe = probe_window(course, users, p_start.to_s, p_end.to_s)
  probe_cost = cost_for(probe)
  full_cost = probe_cost * (c_days.to_f / p_days)
  suggested = suggest_window(probe, p_days, c_start, c_end, c_days, full_cost)
  { slug: slug, course_id: course['id'], type: course['type'],
    course_window: [c_start, c_end], course_days: c_days,
    users: users.size, wikis: course['wikis'],
    probe_window: [p_start, p_end], probe_days: p_days,
    probe_totals: probe, probe_cost_s: probe_cost,
    full_estimate_s: full_cost, suggested: suggested }
end

def print_header(r)
  puts "Course: #{r[:slug]}  (id #{r[:course_id]}, #{r[:type]})"
  puts "  course window: #{r[:course_window][0]} .. #{r[:course_window][1]} (#{r[:course_days]} d)"
  puts "  wikis:         #{r[:wikis].map { |w| "#{w['language']}.#{w['project']}" }.join(', ')}"
  puts "  users probed:  #{r[:users]}"
end

def print_probe_row(label, count, capped)
  puts format('    %-14s %-6d  (capped users: %d)', label + ':', count, capped)
end

def print_probe_totals(p)
  print_probe_row('non-wd revs', p[:non_wd], p[:capped][:non_wd])
  print_probe_row('wikidata',    p[:wikidata], p[:capped][:wikidata])
  print_probe_row('uploads',     p[:uploads], p[:capped][:uploads])
end

def print_probe(r)
  puts '  Probe (calibration window):'
  puts "    window:        #{r[:probe_window][0]} .. #{r[:probe_window][1]} (#{r[:probe_days]} d)"
  print_probe_totals(r[:probe_totals])
  puts format('    probe cost:    %s', fmt_cost(r[:probe_cost_s]))
  puts format('    full estimate: %s  (linear × %.1f)',
              fmt_cost(r[:full_estimate_s]), r[:course_days].to_f / r[:probe_days])
end

def print_suggestion(r)
  s = r[:suggested]
  if s.nil?
    puts '  No useful window found (course has no countable activity).'
    return
  end
  puts "  Suggested window for #{TARGET_MIN}..#{TARGET_MAX}s:"
  puts "    #{s[:start]} .. #{s[:end]}  (#{s[:days]} d)"
  puts format('    estimated cost: %s', fmt_cost(s[:estimate_s]))
end

def print_single(r)
  print_header(r)
  puts
  print_probe(r)
  puts
  print_suggestion(r)
end

def fit_label(s, target_min, target_max)
  return '?'    unless s
  return 'low'  if s < target_min
  return 'fit'  if s <= target_max
  'high'
end

TABLE_FMT = '%-50s %-10s %4s %5s %10s %10s %10s %10s %4s'

def print_table_row(r)
  s = r[:suggested]
  puts format(TABLE_FMT, r[:slug][0, 49], (r[:type] || '')[0, 10], r[:course_days],
              r[:users], fmt_cost(r[:probe_cost_s]), fmt_cost(r[:full_estimate_s]),
              s ? s[:days].to_s : '-', s ? fmt_cost(s[:estimate_s]) : '-',
              fit_label(s && s[:estimate_s], TARGET_MIN, TARGET_MAX))
end

def print_table(rows)
  puts format(TABLE_FMT, 'slug', 'type', 'd', 'users', 'probe', 'full',
              'sugg_d', 'sugg_est', 'fit')
  puts '-' * 130
  rows.each { |r| print_table_row(r) }
end

# ---------- main ----------

if ENV['SLUG']
  r = estimate_for_course(ENV['SLUG'])
  print_single(r)
  exit 0
end

if ENV['IDS']
  ids = ENV['IDS'].split(',').map { |s| s.strip }.reject(&:empty?)
  abort 'No IDs given' if ids.empty?
  rows = []
  ids.each do |id|
    slug = slug_from_id(id)
    if slug.nil?
      warn "[#{id}] could not resolve slug; skipping"
      next
    end
    print "[#{id}] #{slug}  ... "
    $stdout.flush
    begin
      rows << estimate_for_course(slug)
      puts 'ok'
    rescue StandardError => e
      puts "ERROR #{e.class}: #{e.message}"
    end
  end
  puts
  # Sort: best fit first, then closest-to-target by estimate distance.
  rows.sort_by! do |r|
    s = r[:suggested]
    cost = s ? s[:estimate_s] : Float::INFINITY
    fit = fit_label(cost, TARGET_MIN, TARGET_MAX)
    [%w[fit low high ?].index(fit), (cost - (TARGET_MIN + TARGET_MAX) / 2.0).abs]
  end
  print_table(rows)
  exit 0
end

abort 'Set SLUG=... or IDS=12,34,56'
