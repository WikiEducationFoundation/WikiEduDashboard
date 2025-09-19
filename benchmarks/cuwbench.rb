#!/usr/bin/env rails runner
# frozen_string_literal: true

puts "This benchmark WILL WIPE YOUR DATABASE. You must enter 'WIPE' to continue."
input = gets.chomp
exit(1) unless input == 'WIPE'

WikiEduDashboard::Application.load_tasks
Rake::Task['db:reset'].invoke

require "#{Rails.root}/setup/populate_dashboard"
puts 'Copying benchmark course...'
make_copy_of 'https://outreachdashboard.wmflabs.org/courses/CodeTheCity/WODD-Wikidata_Taster_(Saturday_6th_March_2021)'
@course = Course.first

puts 'Warmup...'
ActiveRecord::Base.transaction do
  # Warmup
  UpdateCourseStats.new(@course)
  raise ActiveRecord::Rollback
end

puts '### GC state'

puts GC.stat

raise unless Article.count.zero?

puts '### Cold Database'
result = Benchmark.measure do
  10.times do
    printf('.')
    ActiveRecord::Base.transaction do
      UpdateCourseStats.new(@course)
      raise ActiveRecord::Rollback
    end
  end
end
puts result

raise unless Article.count.zero?

puts '### Hot Database'

ActiveRecord::Base.transaction do
  UpdateCourseStats.new(@course)

  result = Benchmark.measure do
    10.times do
      printf('.')
      UpdateCourseStats.new(@course)
    end
  end
  puts result
  raise ActiveRecord::Rollback
end
