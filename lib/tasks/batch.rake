require 'action_view'
include ActionView::Helpers::DateHelper

namespace :batch do
  desc 'Setup CRON logger to STDOUT'
  task setup_logger: :environment do
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO;
    logger.formatter = ActiveSupport::Logger::SimpleFormatter.new
    Rails.logger = logger
  end

  desc 'Constant data updates'
  task update_constantly: :setup_logger do
    daily_file = 'tmp/batch_update_daily.pid'
    pid_file = 'tmp/batch_update_constantly.pid'
    pause_file = 'tmp/batch_pause.pid'
    if File.exist? pid_file     # Do not run while another instance is running
      Rails.logger.warn I18n.t('tasks.conseq', task: 'batch_update_constantly')
      Kernel.exit
    end
    if File.exist? daily_file   # Do not run while update_daily is running
      Rails.logger.warn I18n.t('tasks.constant', task: 'batch_update_constantly')
      Kernel.exit
    end
    if File.exist? pause_file   # Do not run while updates are paused
      Rails.logger.warn I18n.t('tasks.paused', task: 'batch_update_constantly')
      Kernel.exit
    end

    begin
      File.open(pid_file, 'w') { |f| f.puts Process.pid }
      start = Time.now
      Rails.logger.info 'Constant update tasks are beginning.'
      Rake::Task['course:update_courses'].invoke
      Rake::Task['user:update_users'].invoke
      Rake::Task['revision:update_revisions'].invoke
      Rake::Task['article:update_new_article_views'].invoke
      Rake::Task['article:update_new_ratings'].invoke
      Rake::Task['cache:update_caches'].invoke
      total_time = distance_of_time_in_words(start, Time.now)
      Rails.logger.info "Constant update finished in #{total_time}."
    ensure
      File.delete pid_file if File.exist? pid_file
    end
  end

  desc 'Daily data updates'
  task update_daily: :setup_logger do
    pid_file = 'tmp/batch_update_daily.pid'
    constant_file = 'tmp/batch_update_constantly.pid'
    pause_file = 'tmp/batch_pause.pid'

    if File.exist? pid_file     # Do not run while another instance is running
      Rails.logger.warn I18n.t('tasks.conseq', task: 'batch_update_daily')
      Kernel.exit
    end
    if File.exist? pause_file   # Do not run while updates are paused
      Rails.logger.warn I18n.t('tasks.paused', task: 'batch_update_daily')
      Kernel.exit
    end

    # Wait until update_constantly finishes
    if(File.exist? constant_file)
      # Prevent update_constantly from starting again
      begin
        File.open(pause_file, 'w') { |f| f.puts Process.pid }
        while(File.exist? constant_file)
          Rails.logger.info 'Delaying update_daily task for ten minutes...'
          sleep(10.minutes)
        end
      ensure
        File.delete pause_file if File.exist? pause_file
      end
    end

    begin
      File.open(pid_file, 'w') { |f| f.puts Process.pid }
      start = Time.now
      Rails.logger.info 'Daily update tasks are beginning.'
      Rake::Task['article:update_views'].invoke
      Rake::Task['article:update_all_ratings'].invoke
      Rake::Task['article:update_articles_deleted'].invoke
      Rake::Task['cache:update_caches'].invoke
      total_time = distance_of_time_in_words(start, Time.now)
      Rails.logger.info "Daily update finished in #{total_time}."
    ensure
      File.delete pid_file if File.exist? pid_file
    end
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
      Rake::Task['course:update_courses'].invoke
      Rake::Task['user:update_users'].invoke
      Rake::Task['revision:update_revisions'].invoke
      Rake::Task['article:update_views_all_time'].invoke
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
  end

  desc 'Resume updates'
  task resume: :environment do
    pid_file = 'tmp/batch_pause.pid'
    File.delete pid_file if File.exist? pid_file
  end
end
