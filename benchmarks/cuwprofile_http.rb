#!/usr/bin/env rails runner
# frozen_string_literal: true

# Wall-time profiler for a single UpdateCourseStats run with per-HTTP-call
# instrumentation and a per-stage timeline. Use this as a starting point
# when you need to know which external service (Replica, ReferenceCounterApi,
# LiftWingApi, mediawiki_api) is dominating a slow course update.
#
# Runs against the development DB by default; refuses production. Operates
# on whatever course you point it at — non-destructive: original course
# start/end and needs_update are restored at exit.
#
# Usage:
#     SLUG='Some/Course_slug' bundle exec rails runner benchmarks/cuwprofile_http.rb
#
# Env vars:
#     SLUG            course slug (default: Course.first)
#     MODE            cold | warm | incremental | cold+warm (default: warm)
#                       cold        — clear timeslice state, set needs_update=true
#                       warm        — keep timeslice state, set needs_update=true
#                       incremental — keep state, leave needs_update=false (true
#                                     periodic-sidekiq behavior)
#                       cold+warm   — run cold then warm back-to-back
#     START, END      narrow the course date window to YYYY-MM-DD
#                     (useful for keeping a run under a few minutes)
#     PROGRESS_EVERY  progress tick seconds (default 20)

require 'benchmark'
require 'date'
require_dependency "#{Rails.root}/lib/data_cycle/update_debugger"
require_dependency "#{Rails.root}/app/services/update_course_stats"
require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/reference_counter_api"
require_dependency "#{Rails.root}/lib/lift_wing_api"
require_dependency "#{Rails.root}/lib/wiki_api"

abort 'Refusing to run in production.' if Rails.env.production?

VALID_MODES = %w[cold warm incremental cold+warm].freeze
mode = ENV.fetch('MODE', 'warm')
abort "MODE=#{mode.inspect} not in #{VALID_MODES.inspect}" unless VALID_MODES.include?(mode)

slug = ENV['SLUG']
course = slug ? Course.find_by(slug: slug) : Course.first
abort "Course not found (SLUG=#{slug.inspect})" if course.nil?

orig_start = course.start
orig_end   = course.end
orig_needs_update = course.needs_update
new_start = ENV['START'] ? Date.parse(ENV['START']).to_time.utc : orig_start
new_end   = ENV['END']   ? Date.parse(ENV['END']).to_time.utc   : orig_end

def log(msg) = puts "[#{Time.now.utc.strftime('%H:%M:%S')}] #{msg}"

# ---------- per-run aggregator ----------
def fresh_stats
  Hash.new { |h, k| h[k] = { count: 0, total_s: 0.0, max_s: 0.0, min_s: nil, failed: 0 } }
end

CURRENT = { stats: fresh_stats }

def track(label)
  t = Time.now
  begin
    result = yield
  rescue StandardError
    CURRENT[:stats][label][:failed] += 1
    raise
  end
  s = CURRENT[:stats][label]
  elapsed = Time.now - t
  s[:count] += 1
  s[:total_s] += elapsed
  s[:max_s] = elapsed if elapsed > s[:max_s]
  s[:min_s] = elapsed if s[:min_s].nil? || elapsed < s[:min_s]
  result
end

module ReplicaTiming
  def do_query(_endpoint, _query) = track(:replica_get) { super }
  def do_post(_endpoint, _key, _data) = track(:replica_post) { super }
end
Replica.prepend(ReplicaTiming)

module RefCountTiming
  def get_number_of_references_from_revision_id(_rev_id) = track(:ref_counter_single) { super }
  def get_number_of_references_from_revision_ids(_rev_ids) = track(:ref_counter_batch) { super }
end
ReferenceCounterApi.prepend(RefCountTiming)

module LiftWingTiming
  def get_revision_data(_rev_ids) = track(:lift_wing_batch) { super }
end
LiftWingApi.prepend(LiftWingTiming)

module WikiApiTiming
  def query(_params) = track(:wiki_api_query) { super }
end
WikiApi.prepend(WikiApiTiming)

# ---------- stage-boundary logger ----------
stage_log_t0 = nil
UpdateDebugger.prepend(Module.new do
  define_method(:log_update_progress) do |step|
    now = Time.now
    delta = stage_log_t0 ? now - stage_log_t0 : 0
    stage_log_t0 = now
    $stdout.puts format('[%s] stage :%s (+%.2fs)', now.utc.strftime('%H:%M:%S'), step, delta)
    $stdout.flush
    super(step)
  end
end)

# ---------- per-mode setup ----------
def clear_timeslices(course)
  before = {
    cwt: CourseWikiTimeslice.where(course:).count,
    acst: ArticleCourseTimeslice.where(course:).count,
    cust: CourseUserWikiTimeslice.where(course:).count
  }
  ArticleCourseTimeslice.where(course:).delete_all
  CourseUserWikiTimeslice.where(course:).delete_all
  CourseWikiTimeslice.where(course:).delete_all
  log "  cleared: #{before}"
end

def prepare_run(course, run_mode)
  case run_mode
  when 'cold'
    log "Clearing pre-existing timeslice state for cold run..."
    clear_timeslices(course)
    course.update!(needs_update: true)
  when 'warm'
    course.update!(needs_update: true)
  when 'incremental'
    course.update!(needs_update: false) if course.needs_update
  end
end

# ---------- date narrowing (avoid set_needs_update_for_timeslice callback) ----------
course.start = new_start if course.start != new_start
course.end   = new_end   if course.end != new_end
course.save! if course.changed?

at_exit do
  course.reload
  course.update(start: orig_start, end: orig_end, needs_update: orig_needs_update)
  log "Restored course state: #{orig_start} .. #{orig_end}, needs_update=#{orig_needs_update}"
end

log "Course: #{course.slug} (id=#{course.id})  mode=#{mode}"
log "Original date range: #{orig_start} .. #{orig_end}"
log "Active date range:   #{new_start} .. #{new_end}"

# ---------- progress ticker ----------
progress_every = Integer(ENV.fetch('PROGRESS_EVERY', '20'))
done = false
Thread.new do
  loop do
    sleep progress_every
    break if done
    s = CURRENT[:stats]
    log "  progress: " \
        "replica=#{s[:replica_get][:count]}+#{s[:replica_post][:count]}  " \
        "refcnt_b=#{s[:ref_counter_batch][:count]} refcnt_s=#{s[:ref_counter_single][:count]}  " \
        "liftwing=#{s[:lift_wing_batch][:count]}  wikiapi=#{s[:wiki_api_query][:count]}"
  end
end

# ---------- run ----------
runs = mode == 'cold+warm' ? %w[cold warm] : [mode]
results = {}

runs.each do |run_mode|
  CURRENT[:stats] = fresh_stats
  stage_log_t0 = nil
  course.reload
  prepare_run(course, run_mode)
  log "=== UpdateCourseStats #{run_mode} starting ==="
  stats_obj = nil
  total = Benchmark.realtime { stats_obj = UpdateCourseStats.new(course) }
  log "=== UpdateCourseStats #{run_mode} done in #{total.round(2)}s ==="
  results[run_mode] = {
    total: total,
    stats: CURRENT[:stats],
    timings: stats_obj.instance_variable_get(:@debugger).stage_timings
  }
end
done = true

# ---------- summary ----------
def print_endpoint_row(lbl, s)
  return if s[:count].zero? && s[:failed].zero?
  avg = s[:count].zero? ? 0.0 : s[:total_s] / s[:count]
  puts format('%-22s %8d %10.2f %8.3f %8.3f %8.3f %6d',
              lbl, s[:count], s[:total_s], avg, s[:min_s] || 0, s[:max_s], s[:failed])
end

def print_run_summary(label, stats, total)
  puts
  puts "### #{label} run — wall #{total.round(2)}s"
  puts format('%-22s %8s %10s %8s %8s %8s %6s',
              'endpoint', 'count', 'total_s', 'avg_s', 'min_s', 'max_s', 'fails')
  puts '-' * 82
  stats.each { |lbl, s| print_endpoint_row(lbl, s) }
  total_http = stats.values.sum { |s| s[:total_s] }
  pct = total.positive? ? (total_http / total * 100).round(0) : 0
  puts format('  Total HTTP time: %.1fs (%d%% of wall time)', total_http, pct)
end

def print_stage_timeline(label, timings)
  puts
  puts "=== #{label} per-stage timings ==="
  prev = nil
  timings.each do |step, ts|
    delta = prev ? (ts - prev) : 0
    puts format('  %-40s +%7.3fs', step, delta)
    prev = ts
  end
end

results.each { |label, r| print_run_summary(label, r[:stats], r[:total]) }
results.each { |label, r| print_stage_timeline(label, r[:timings]) }

puts
puts '=== CourseWikiTimeslice state after run ==='
puts format('  total: %d', course.course_wiki_timeslices.count)
course.course_wiki_timeslices.group(:wiki_id).count.each do |wid, n|
  wiki = Wiki.find(wid)
  puts format('    wiki=%d (%s/%s): %d', wid, wiki.language, wiki.project, n)
end
