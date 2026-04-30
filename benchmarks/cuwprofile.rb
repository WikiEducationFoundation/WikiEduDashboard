#!/usr/bin/env rails runner
# frozen_string_literal: true

# StackProf wall-time profile for a single UpdateCourseStats run.
# Outputs profile.json — drag into https://speedscope.app to view.
#
# Defaults to the development DB. SETUP=1 wipes the DB and is therefore
# restricted to test.
#
#     bundle exec rails runner benchmarks/cuwprofile.rb              # uses dev DB
#     RAILS_ENV=test SETUP=1 bundle exec rails runner benchmarks/cuwprofile.rb
#
# Env vars:
#   SLUG=...       — course to profile (default: Course.first)
#   SETUP=1        — wipe the DB and clone COURSE_URL before profiling (RAILS_ENV=test only)
#   COURSE_URL=... — live course to clone when SETUP=1
#   INTERVAL=N     — StackProf sampling interval in microseconds (default 10000 = 10ms)
#   OUTPUT=path    — profile output path (default profile.json)

require 'benchmark'

abort 'Refusing to run in production.' if Rails.env.production?
abort 'SETUP=1 wipes the DB; run with RAILS_ENV=test.' if ENV['SETUP'] == '1' && !Rails.env.test?

DEFAULT_COURSE_URL = 'https://outreachdashboard.wmflabs.org/courses/CodeTheCity/' \
                     'WODD-Wikidata_Taster_(Saturday_6th_March_2021)'
course_url = ENV.fetch('COURSE_URL', DEFAULT_COURSE_URL)
interval = Integer(ENV.fetch('INTERVAL', '10000'))
output = ENV.fetch('OUTPUT', 'profile.json')

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
puts "Profiling course: #{@course.slug}"

stats = nil
elapsed = Benchmark.realtime do
  profile = StackProf.run(mode: :wall, raw: true, interval:) do
    stats = UpdateCourseStats.new(@course)
  end
  File.open(output, 'w') { |f| f.puts(JSON.dump(profile)) }
end

puts "total=#{format('%.3fs', elapsed)}  profile written to #{output}"
puts 'Stage timings:'
prev = nil
stats.instance_variable_get(:@debugger).stage_timings.each do |step, time|
  secs = prev ? (time - prev).to_f : 0.0
  prev = time
  puts format('  %-40s  %7.3fs', step, secs)
end
