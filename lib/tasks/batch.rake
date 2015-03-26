namespace :batch do
  desc 'Constant data updates'
  task update_constantly: :environment do
    pid_file = 'tmp/batch_update_constantly.pid'
    pause_file = 'tmp/batch_pause.pid'
    if File.exist? pid_file
      Rails.logger.warn I18n.t('tasks.conseq', task: 'batch_update_constantly')
      Kernel.exit
    end
    if File.exist? pause_file
      Rails.logger.warn I18n.t('tasks.paused', task: 'batch_update_constantly')
      Kernel.exit
    end
    File.open(pid_file, 'w') { |f| f.puts Process.pid }
    begin
      Rails.logger.info 'Running constant update tasks'
      Rake::Task['course:update_courses'].invoke
      Rake::Task['user:update_users'].invoke
      Rake::Task['revision:update_revisions'].invoke
      Rake::Task['article:update_new_article_views'].invoke
      Rake::Task['article:update_new_ratings'].invoke
      Rake::Task['cache:update_caches'].invoke
    ensure
      File.delete pid_file
    end
  end

  desc 'Daily data updates'
  task update_daily: :environment do
    pid_file = 'tmp/batch_update_daily.pid'
    pause_file = 'tmp/batch_pause.pid'
    if File.exist? pid_file
      Rails.logger.warn I18n.t('tasks.conseq', task: 'batch_update_daily')
      Kernel.exit
    end
    if File.exist? pause_file
      Rails.logger.warn I18n.t('tasks.paused', task: 'batch_update_daily')
      Kernel.exit
    end
    File.open(pid_file, 'w') { |f| f.puts Process.pid }
    begin
      Rails.logger.info 'Running daily update tasks'
      Rake::Task['article:update_views'].invoke
      Rake::Task['article:update_all_ratings'].invoke
      Rake::Task['article:update_articles_deleted'].invoke
      Rake::Task['cache:update_caches'].invoke
    ensure
      File.delete pid_file
    end
  end

  desc 'Initialize the database from scratch'
  task initialize: :environment do
    pid_file = 'tmp/batch_initialize.pid'
    if File.exist? pid_file
      Rails.logger.warn I18n.t('tasks.conseq', task: 'batch_initialize')
      Kernel.exit
    end
    File.open(pid_file, 'w') { |f| f.puts Process.pid }
    begin
      Rails.logger.info 'Running initialization tasks'
      Rake::Task['course:update_courses'].invoke
      Rake::Task['user:update_users'].invoke
      Rake::Task['revision:update_revisions'].invoke
      Rake::Task['article:update_views_all_time'].invoke
      Rake::Task['cache:update_caches'].invoke
    ensure
      File.delete pid_file
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
    File.delete pid_file
  end
end
