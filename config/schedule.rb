# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, '/path/to/my/cron_log.log'
#
# every 2.hours do
#   command '/usr/bin/some_great_command'
#   runner 'MyModel.some_method'
#   rake 'some:great:rake:task'
# end
#
# every 4.days do
#   runner 'AnotherModel.prune_old_records'
# end

# Learn more: http://github.com/javan/whenever

set :output, 'log/cron.log'

every 4.minutes do
  rake 'batch:update_constantly'
end

every 1.day, at: '4:30 am' do
  rake 'batch:update_daily'
end

every 1.day, at: '4:35 am' do
  rake 'batch:update_views'
end

every [:monday, :tuesday, :wednesday, :thursday], at: '10:15 am' do
  rake 'batch:survey_update'
end

every [:monday, :tuesday, :wednesday, :thursday], at: '10:30 am' do
  rake 'experiments:fall_2017_cmu_experiment'
end
