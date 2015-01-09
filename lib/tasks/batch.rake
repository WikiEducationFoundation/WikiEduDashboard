namespace :batch do

  desc 'Constant data updates'
  task :update_constantly => :environment do
    Rails.logger.info "Running hourly update tasks"
    %W[course:update_courses user:update_users revision:update_revisions cache:update_caches].each do |task_name|
      Rake::Task[task_name].invoke
    end
  end

  desc 'Daily data updates'
  task :update_daily => :environment do
    Rails.logger.info "Running daily update tasks"
    %W[article:update_views cache:update_caches].each do |task_name|
      Rake::Task[task_name].invoke
    end
  end

  desc 'Initialize the database from scratch'
  task :initialize => :environment do
    Rails.logger.info "Running initialization tasks"
    %W[course:update_courses user:update_users revision:update_revisions article:update_views_all_time cache:update_caches].each do |task_name|
      Rake::Task[task_name].invoke
    end
  end

end