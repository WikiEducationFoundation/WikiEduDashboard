# frozen_string_literal: true

require 'action_view'

namespace :batch do
  desc 'Constant data updates'
  task update_constantly: :environment do
    require "#{Rails.root}/lib/data_cycle/constant_update"
    ConstantUpdate.new
  end

  desc 'Short data updates'
  task update_shortly: :environment do
    ShortUpdateWorker.perform_async
  end

  desc 'Daily data updates'
  task update_daily: :environment do
    require "#{Rails.root}/lib/data_cycle/daily_update"
    DailyUpdate.new
  end

  desc 'Survey updates'
  task survey_update: :environment do
    require "#{Rails.root}/lib/data_cycle/survey_update"
    SurveyUpdate.new
  end

  desc 'View import updates'
  task update_views: :environment do
    require "#{Rails.root}/lib/data_cycle/views_update"
    ViewsUpdate.new
  end

  desc 'Pause updates'
  task pause: :environment do
    pid_file = 'tmp/batch_pause.pid'
    File.open(pid_file, 'w') { |f| f.puts Process.pid }
    Raven.capture_message 'Updates paused.', level: 'warn'
  end

  desc 'Resume updates'
  task resume: :environment do
    pid_file = 'tmp/batch_pause.pid'
    File.delete pid_file if File.exist? pid_file
    Raven.capture_message 'Updates resumed.', level: 'warn'
  end
end
