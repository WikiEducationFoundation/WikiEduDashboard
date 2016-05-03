require 'action_view'
include ActionView::Helpers::DateHelper
require "#{Rails.root}/lib/importers/revision_score_importer"
require "#{Rails.root}/lib/data_cycle/constant_update"
require "#{Rails.root}/lib/data_cycle/daily_update"

namespace :batch do
  desc 'Setup CRON logger to STDOUT'
  task setup_logger: :environment do
    $stdout.sync = true
    logger = Logger.new $stdout
    logger.level = Figaro.env.cron_log_debug ? Logger::DEBUG : Logger::INFO
    logger.formatter = ActiveSupport::Logger::SimpleFormatter.new
    Rails.logger = logger
  end

  desc 'Constant data updates'
  task update_constantly: :environment do
    ConstantUpdate.new
  end

  desc 'Daily data updates'
  task update_daily: :setup_logger do
    DailyUpdate.new
  end

  desc 'Initialize the database from scratch'
  task initialize: :environment do
    pid_file = 'tmp/batch_initialize.pid'
    if File.exist? pid_file
      Rails.logger.warn I18n.t('tasks.conseq', task: 'batch_initialize')
      Kernel.exit
    end
    begin
      File.open(pid_file, 'w') { |f| f.puts Process.pid }
      Rails.logger.info 'Running initialization tasks'
      Rake::Task['cohort:add_cohorts'].invoke
      Rake::Task['legacy_course:update_courses'].invoke
      Rake::Task['user:update_users'].invoke
      Rake::Task['revision:update_revisions'].invoke
      Rake::Task['article:update_views_all_time']
        .invoke unless Figaro.env.no_views
      Rake::Task['cache:update_caches'].invoke
      Rails.logger.info 'Initialization tasks have finished'
    ensure
      File.delete pid_file if File.exist? pid_file
    end
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
