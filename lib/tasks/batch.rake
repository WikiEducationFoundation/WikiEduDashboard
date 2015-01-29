namespace :batch do

  desc 'Constant data updates'
  task :update_constantly => :environment do
    pid_file = '/tmp/batch_update_constantly.pid'
    raise 'batch_update_constantly is already running!' if File.exists? pid_file
    File.open(pid_file, 'w'){|f| f.puts Process.pid}
    begin
      Rails.logger.info "Running constant update tasks"
      Rake::Task['course:update_courses'].invoke
      Rake::Task['user:update_users'].invoke
      Rake::Task['revision:update_revisions'].invoke
      Rake::Task['article:update_new_article_views'].invoke
      Rake::Task['cache:update_caches'].invoke
    ensure
      File.delete pid_file
    end
  end

  desc 'Daily data updates'
  task :update_daily => :environment do
    pid_file = '/tmp/batch_update_daily.pid'
    raise 'batch_update_daily is already running!' if File.exists? pid_file
    File.open(pid_file, 'w'){|f| f.puts Process.pid}
    begin
      Rails.logger.info "Running daily update tasks"
      Rake::Task['article:update_views'].invoke
      Rake::Task['cache:update_caches'].invoke
    ensure
      File.delete pid_file
    end
  end

  desc 'Initialize the database from scratch'
  task :initialize => :environment do
    pid_file = '/tmp/batch_initialize.pid'
    raise 'batch_initialize is already running!' if File.exists? pid_file
    File.open(pid_file, 'w'){|f| f.puts Process.pid}
    begin
      Rails.logger.info "Running initialization tasks"
      Rake::Task['course:update_courses'].invoke
      Rake::Task['user:update_users'].invoke
      Rake::Task['revision:update_revisions'].invoke
      Rake::Task['article:update_views_all_time'].invoke
      Rake::Task['cache:update_caches'].invoke
    ensure
      File.delete pid_file
    end
  end

end
