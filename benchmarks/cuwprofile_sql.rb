#!/usr/bin/env rails runner
# frozen_string_literal: true

# Wall-time SQL profiler for an UpdateCourseStats run. Subscribes to
# sql.active_record notifications and attributes each query to (stage, table,
# operation), and tracks BEGIN/COMMIT/ROLLBACK to surface transaction durations
# per stage. Use this to find which tables and queries dominate each stage —
# especially update_caches and friends, where DB-side cost is what matters.
#
# Runs against the development DB by default; refuses production. Operates on
# whatever course you point it at — non-destructive: original course start/end
# and needs_update are restored at exit.
#
# Usage:
#     SLUG='Some/Course_slug' bundle exec rails runner benchmarks/cuwprofile_sql.rb
#
# Env vars:
#     SLUG            course slug (default: Course.first)
#     MODE            cold | warm | incremental | cold+warm (default: warm)
#                       cold        — clear timeslice state, set needs_update=true
#                       warm        — keep timeslice state, set needs_update=true
#                       incremental — keep state, leave needs_update=false
#                                     (true periodic-sidekiq behavior)
#                       cold+warm   — run cold then warm back-to-back
#     START, END      narrow the course date window to YYYY-MM-DD
#     TOP_TABLES      how many table-rows to show per stage (default 10)

require 'benchmark'
require 'date'
require_dependency "#{Rails.root}/lib/data_cycle/update_debugger"
require_dependency "#{Rails.root}/app/services/update_course_stats"

abort 'Refusing to run in production.' if Rails.env.production?

VALID_MODES = %w[cold warm incremental cold+warm].freeze
mode = ENV.fetch('MODE', 'warm')
abort "MODE=#{mode.inspect} not in #{VALID_MODES.inspect}" unless VALID_MODES.include?(mode)

slug = ENV['SLUG']
course = slug ? Course.find_by(slug: slug) : Course.first
abort "Course not found (SLUG=#{slug.inspect})" if course.nil?
TOP_TABLES = Integer(ENV.fetch('TOP_TABLES', '10'))

orig_start = course.start
orig_end   = course.end
orig_needs_update = course.needs_update
new_start = ENV['START'] ? Date.parse(ENV['START']).to_time.utc : orig_start
new_end   = ENV['END']   ? Date.parse(ENV['END']).to_time.utc   : orig_end

def log(msg) = puts "[#{Time.now.utc.strftime('%H:%M:%S')}] #{msg}"

# ---------- per-run aggregator ----------

# stage_name -> { table -> { op -> { count, total_s } } }
def fresh_sql_stats
  Hash.new do |h, k|
    h[k] = Hash.new { |h2, k2| h2[k2] = Hash.new { |h3, k3| h3[k3] = { count: 0, total_s: 0.0 } } }
  end
end

CURRENT = { sql: fresh_sql_stats, transactions: [],
            pending_queries: [], pending_txns: [], txn_open_at: nil }

# ---------- stage attribution via UpdateDebugger hook ----------
#
# `log_update_progress(:X)` fires AFTER the work named X completes. Queries
# generated during that work happen BEFORE the marker. We buffer queries and
# transaction completions in a pending list and flush them to the marker that
# fires next — that way "stage :X" in the report names the work whose end the
# marker announced, which is what a reader naturally expects.

UpdateDebugger.prepend(Module.new do
  define_method(:log_update_progress) do |step|
    CURRENT[:pending_queries].each do |table, op, dur|
      bucket = CURRENT[:sql][step][table][op]
      bucket[:count] += 1
      bucket[:total_s] += dur
    end
    CURRENT[:pending_queries].clear
    CURRENT[:pending_txns].each { |t| CURRENT[:transactions] << t.merge(stage: step) }
    CURRENT[:pending_txns].clear
    super(step)
  end
end)

# ---------- SQL classification ----------

# Returns [kind, table, op] where kind is one of:
#   :begin, :commit, :rollback, :savepoint, :query, :other
def classify_sql(sql)
  case sql
  when /\ABEGIN\b/i, /\ASTART TRANSACTION\b/i then [:begin, nil, nil]
  when /\ACOMMIT\b/i                          then [:commit, nil, nil]
  when /\AROLLBACK\b/i                        then [:rollback, nil, nil]
  when /\ASAVEPOINT\b/i, /\ARELEASE\b/i       then [:savepoint, nil, nil]
  else
    op = sql_op(sql)
    op ? [:query, extract_table(sql, op), op] : [:other, nil, nil]
  end
end

def sql_op(sql)
  case sql
  when /\ASELECT\b/i then 'SELECT'
  when /\AUPDATE\b/i then 'UPDATE'
  when /\AINSERT\b/i then 'INSERT'
  when /\ADELETE\b/i then 'DELETE'
  end
end

# Heuristic table extraction. ActiveRecord-generated SQL is regular enough that
# this catches the common cases; "(unknown)" surfaces edge cases for inspection.
def extract_table(sql, op)
  m = case op
      when 'SELECT', 'DELETE' then sql.match(/\bFROM\s+`?([\w]+)`?/i)
      when 'UPDATE'           then sql.match(/\AUPDATE\s+`?([\w]+)`?/i)
      when 'INSERT'           then sql.match(/\AINSERT\s+(?:IGNORE\s+)?INTO\s+`?([\w]+)`?/i)
      end
  m ? m[1] : '(unknown)'
end

# ---------- subscriber ----------

# Queries are buffered into pending_queries until the next marker fires (then
# they're attributed to that marker — see UpdateDebugger hook above).
# Transactions are buffered as completed (BEGIN, COMMIT) pairs and flushed the
# same way; each transaction is attributed to whichever marker fires after it
# commits.
def record_txn_event(kind, started, finished)
  if kind == :begin
    CURRENT[:txn_open_at] = started
  elsif CURRENT[:txn_open_at]
    CURRENT[:pending_txns] << { duration: finished - CURRENT[:txn_open_at], kind: kind }
    CURRENT[:txn_open_at] = nil
  end
end

ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, t0, t1, _id, payload|
  next if payload[:name] == 'SCHEMA'
  next if payload[:cached]

  kind, table, op = classify_sql(payload[:sql].to_s)
  case kind
  when :query then CURRENT[:pending_queries] << [table, op, t1 - t0]
  when :begin, :commit, :rollback then record_txn_event(kind, t0, t1)
  end
end

# ---------- per-mode setup (mirrors cuwprofile_http.rb) ----------

def clear_timeslices(course)
  before = {
    cwt: CourseWikiTimeslice.where(course:).count,
    act: ArticleCourseTimeslice.where(course:).count,
    cuwt: CourseUserWikiTimeslice.where(course:).count
  }
  ArticleCourseTimeslice.where(course:).delete_all
  CourseUserWikiTimeslice.where(course:).delete_all
  CourseWikiTimeslice.where(course:).delete_all
  log "  cleared: #{before}"
end

def prepare_run(course, run_mode)
  case run_mode
  when 'cold'
    log 'Clearing pre-existing timeslice state for cold run...'
    clear_timeslices(course)
    course.update!(needs_update: true)
  when 'warm'
    course.update!(needs_update: true)
  when 'incremental'
    course.update!(needs_update: false) if course.needs_update
  end
end

# ---------- summary printers ----------

def stage_rows(stage_data)
  stage_data.flat_map do |table, ops|
    ops.map { |op, counters| [table, op, counters[:count], counters[:total_s]] }
  end.sort_by { |r| -r[3] }
end

def print_stage_top_rows(rows)
  rows.first(TOP_TABLES).each do |table, op, count, total|
    pct = rows.sum { |r| r[3] }
    pct = pct.positive? ? (total / pct * 100).round(1) : 0
    puts format('    %-38s %-7s %8d %10.3f %5.1f', table[0, 38], op, count, total, pct)
  end
end

def print_stage_remainder(rows)
  return unless rows.size > TOP_TABLES
  tail = rows.drop(TOP_TABLES)
  puts format('    %-38s %-7s %8d %10.3f %5s',
              "(#{tail.size} more rows)", '', tail.sum { |r| r[2] }, tail.sum { |r| r[3] }, '')
end

def print_stage_breakdown(stage_data)
  rows = stage_rows(stage_data)
  puts format('    %-38s %-7s %8s %10s %5s', 'table', 'op', 'count', 'total_s', '%')
  print_stage_top_rows(rows)
  print_stage_remainder(rows)
  puts format('    total per stage:                                  %10.3fs',
              rows.sum { |r| r[3] })
end

def print_transactions(txns)
  return if txns.empty?
  by_stage = txns.group_by { |t| t[:stage] }
  puts
  puts '=== Transactions by stage ==='
  puts format('  %-32s %4s %10s %10s %10s', 'stage', 'n', 'total_s', 'max_s', 'mean_s')
  puts '-' * 80
  by_stage.each do |stage, ts|
    durs = ts.map { |t| t[:duration] }
    puts format('  %-32s %4d %10.3f %10.3f %10.3f',
                stage.to_s, ts.size, durs.sum, durs.max, durs.sum / ts.size)
  end
end

def print_run_summary(label, r)
  puts
  puts "### #{label} run — wall #{r[:total].round(2)}s"
  r[:sql].each do |stage, stage_data|
    next if stage_data.empty?
    puts
    puts "=== stage :#{stage} ==="
    print_stage_breakdown(stage_data)
  end
  print_transactions(r[:transactions])
end

# ---------- date narrowing & restoration ----------

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

# ---------- run ----------

runs = mode == 'cold+warm' ? %w[cold warm] : [mode]
results = {}

runs.each do |run_mode|
  CURRENT[:sql] = fresh_sql_stats
  CURRENT[:transactions] = []
  CURRENT[:pending_queries] = []
  CURRENT[:pending_txns] = []
  CURRENT[:txn_open_at] = nil
  course.reload
  prepare_run(course, run_mode)
  log "=== UpdateCourseStats #{run_mode} starting ==="
  total = Benchmark.realtime { UpdateCourseStats.new(course) }
  log "=== UpdateCourseStats #{run_mode} done in #{total.round(2)}s ==="
  results[run_mode] = { total: total, sql: CURRENT[:sql], transactions: CURRENT[:transactions] }
end

results.each { |label, r| print_run_summary(label, r) }
