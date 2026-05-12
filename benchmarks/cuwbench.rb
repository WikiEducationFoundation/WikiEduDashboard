#!/usr/bin/env rails runner
# frozen_string_literal: true

# Wall-time benchmark for UpdateCourseStats.
#
# Defaults to the development DB so you can bench against your existing data;
# each iteration is wrapped in a transaction that's rolled back, so persisted
# state is unchanged. SETUP=1 wipes the DB and is therefore restricted to test.
#
#     bundle exec rails runner benchmarks/cuwbench.rb              # uses dev DB
#     RAILS_ENV=test SETUP=1 bundle exec rails runner benchmarks/cuwbench.rb
#
# Env vars:
#   SLUG=...       — course to bench (default: Course.first)
#   SETUP=1        — wipe the DB and clone COURSE_URL (RAILS_ENV=test only)
#   COURSE_URL=... — live course to clone when SETUP=1 (defaults to the WODD Wikidata Taster)
#   ITERATIONS=N   — cold and hot iterations to run (default 3 each)
#   MODE=cold|hot|both — which loop to run (default both)
#   SNAPSHOT=path  — instead of the bench loops, run one update and write a JSON snapshot of
#                    the resulting stats to `path` (for before/after comparison of behavior
#                    changes). Uses a rollback transaction, no persistent changes.

require 'benchmark'
require 'json'

abort 'Refusing to run in production.' if Rails.env.production?
abort 'SETUP=1 wipes the DB; run with RAILS_ENV=test.' if ENV['SETUP'] == '1' && !Rails.env.test?

DEFAULT_COURSE_URL = 'https://outreachdashboard.wmflabs.org/courses/CodeTheCity/' \
                     'WODD-Wikidata_Taster_(Saturday_6th_March_2021)'
course_url = ENV.fetch('COURSE_URL', DEFAULT_COURSE_URL)
iterations = Integer(ENV.fetch('ITERATIONS', '3'))
mode = ENV.fetch('MODE', 'both')

if ENV['SETUP'] == '1'
  WikiEduDashboard::Application.load_tasks
  puts "Resetting #{Rails.env} database..."
  Rake::Task['db:reset'].invoke
  require "#{Rails.root}/setup/populate_dashboard"
  puts "Copying benchmark course: #{course_url}"
  make_copy_of(course_url)
end

slug = ENV['SLUG']
@course = slug ? Course.find_by(slug: slug) : Course.first
abort "Course not found (SLUG=#{slug.inspect})" if @course.nil?
puts "Benchmarking course: #{@course.slug}"

def format_stage_durations(timings)
  prev = nil
  rows = timings.map do |step, time|
    seconds = prev ? (time - prev).to_f : 0.0
    prev = time
    [step.to_s, seconds]
  end
  # Drop the first row (start marker, always 0).
  rows = rows.drop(1)
  width = rows.map { |r| r[0].length }.max
  rows.map { |step, secs| format("  %-#{width}s  %7.3fs", step, secs) }.join("\n")
end

def measure_update(course)
  stats = nil
  elapsed = Benchmark.realtime { stats = UpdateCourseStats.new(course) }
  [elapsed, stats.instance_variable_get(:@debugger).stage_timings]
end

def print_sample(label, index, elapsed, timings)
  puts "[#{label} ##{index}] total=#{format('%.3fs', elapsed)}"
  puts format_stage_durations(timings)
end

def print_summary(label, samples)
  return if samples.empty?
  totals = samples.map(&:first)
  mean = totals.sum / totals.size
  puts "[#{label}] n=#{samples.size} mean=#{format('%.3fs', mean)} " \
       "min=#{format('%.3fs', totals.min)} max=#{format('%.3fs', totals.max)}"
end

# Structured snapshot of aggregates produced by an UpdateCourseStats run, for before/after
# comparison. Keys and nested hashes are sorted so a naive `diff` on two snapshots is readable.
def capture_snapshot(course)
  course.reload
  stat = CourseStat.find_by(course_id: course.id)
  {
    'course_stat_stats_hash' => sort_deep(stat&.stats_hash),
    'course_counts' => course_counts(course),
    'per_wiki_timeslice_totals' => course.wikis.sort_by(&:id).map { |w|
      wiki_timeslice_totals(course, w)
    }
  }
end

def course_counts(course)
  {
    'revision_count' => course.revision_count,
    'article_count' => course.article_count,
    'new_article_count' => course.new_article_count,
    'user_count' => course.user_count,
    'character_sum' => course.character_sum,
    'view_sum' => course.view_sum,
    'references_count' => course.references_count,
    'trained_count' => course.trained_count,
    'upload_count' => course.upload_count
  }.sort.to_h
end

def wiki_timeslice_totals(course, wiki)
  ts = CourseWikiTimeslice.for_course_and_wiki(course, wiki)
  {
    'wiki_id' => wiki.id,
    'project' => wiki.project,
    'language' => wiki.language,
    'timeslice_count' => ts.count,
    'revision_count_sum' => ts.sum(:revision_count),
    'character_sum_sum' => ts.sum(:character_sum),
    'references_count_sum' => ts.sum(:references_count)
  }
end

def sort_deep(obj)
  case obj
  when Hash then obj.sort.to_h { |k, v| [k, sort_deep(v)] }
  when Array then obj.map { |v| sort_deep(v) }
  else obj
  end
end

if ENV['SNAPSHOT']
  out = ENV['SNAPSHOT']
  puts "### Snapshot run -> #{out} (forcing full reprocess via needs_update)"
  ActiveRecord::Base.transaction do
    @course.update(needs_update: true)
    elapsed, timings = measure_update(@course)
    print_sample('snapshot', 1, elapsed, timings)
    File.write(out, JSON.pretty_generate(capture_snapshot(@course)))
    puts "Snapshot written to #{out}"
    raise ActiveRecord::Rollback
  end
  exit 0
end

puts '### Warmup'
ActiveRecord::Base.transaction do
  measure_update(@course)
  raise ActiveRecord::Rollback
end

cold_samples = []
if %w[cold both].include?(mode)
  puts "\n### Cold (rollback between iterations)"
  iterations.times do |i|
    ActiveRecord::Base.transaction do
      elapsed, timings = measure_update(@course)
      cold_samples << [elapsed, timings]
      print_sample('cold', i + 1, elapsed, timings)
      raise ActiveRecord::Rollback
    end
  end
  print_summary('cold', cold_samples)
end

hot_samples = []
if %w[hot both].include?(mode)
  puts "\n### Hot (persisted first update, then re-run)"
  ActiveRecord::Base.transaction do
    measure_update(@course) # seed persisted state
    iterations.times do |i|
      elapsed, timings = measure_update(@course)
      hot_samples << [elapsed, timings]
      print_sample('hot', i + 1, elapsed, timings)
    end
    print_summary('hot', hot_samples)
    raise ActiveRecord::Rollback
  end
end
