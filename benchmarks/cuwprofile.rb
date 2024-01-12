#!/usr/bin/env rails runner
# frozen_string_literal: true

puts "This profile WILL WIPE YOUR DATABASE. You must enter 'WIPE' to continue."
input = gets.chomp
exit(1) unless input == 'WIPE'

WikiEduDashboard::Application.load_tasks
Rake::Task['db:reset'].invoke

require Rails.root.join('setup/populate_dashboard')
puts 'Copying benchmark course...'
make_copy_of 'https://outreachdashboard.wmflabs.org/courses/CodeTheCity/WODD-Wikidata_Taster_(Saturday_6th_March_2021)'
@course = Course.first

profile = StackProf.run(mode: :wall, raw: true, interval: 10000) do
  UpdateCourseStats.new(@course)
end

# Drag this file into https://speedscope.app
File.open('profile.json', 'w') { |f| f.puts(JSON.dump(profile)) }
