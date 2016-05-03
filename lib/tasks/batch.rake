require 'action_view'
include ActionView::Helpers::DateHelper
require "#{Rails.root}/lib/importers/revision_score_importer"
require "#{Rails.root}/lib/data_cycle/constant_update"

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
    pid_file = 'tmp/batch_update_daily.pid'
    constant_file = 'tmp/batch_update_constantly.pid'
    pause_file = 'tmp/batch_pause.pid'
    sleep_file = 'tmp/batch_sleep_10.pid'

    if File.exist? pid_file     # Do not run while another instance is running
      Rails.logger.warn I18n.t('tasks.conseq', task: 'batch_update_daily')
      Kernel.exit if pid_file_process_running?(pid_file)
    end
    if File.exist? pause_file   # Do not run while updates are paused
      Rails.logger.warn I18n.t('tasks.paused', task: 'batch_update_daily')
      Kernel.exit
    end

    # Wait until update_constantly finishes
    if File.exist? constant_file
      # Prevent update_constantly from starting again
      begin
        File.open(sleep_file, 'w') { |f| f.puts Process.pid }
        while File.exist? constant_file
          Rails.logger.info 'Delaying update_daily task for ten minutes...'
          sleep(10.minutes)
        end
      ensure
        File.delete sleep_file if File.exist? sleep_file
      end
    end

    begin
      File.open(pid_file, 'w') { |f| f.puts Process.pid }
      start = Time.zone.now

      Rails.logger.info 'Daily update tasks are beginning.'
      Rake::Task['article:import_assigned_articles'].invoke
      Rake::Task['article:rebuild_articles_courses'].invoke
      Rake::Task['article:update_views'].invoke unless ENV['no_views']
      Rake::Task['article:update_all_ratings'].invoke
      Rake::Task['article:update_article_status'].invoke

      Rake::Task['upload:find_deleted_files'].invoke
      Rake::Task['upload:import_all_uploads'].invoke
      Rake::Task['upload:update_usage_count'].invoke
      Rake::Task['upload:get_thumbnail_urls'].invoke

      Rake::Task['cache:update_caches'].invoke

      total_time = distance_of_time_in_words(start, Time.zone.now)
      Rails.logger.info "Daily update finished in #{total_time}."
      Raven.capture_message 'Daily update finished.',
                            level: 'info',
                            tags: { update_time: total_time },
                            extra: { exact_update_time: (Time.zone.now - start) }
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
