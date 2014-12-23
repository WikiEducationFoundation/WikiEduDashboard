namespace :batch do

  desc 'Pull all new data from sources and store appropriately'

  task :update_all => :environment do
    # Update courses and course users
    Rake::Task["course:update_courses"].invoke

    # Update user trained status
    Rake::Task["user:update_users"].invoke

    # Update revisions and articles
    Rake::Task["revision:update_revisions"].invoke

    # Update caches for all models
    Rake::Task["cache:update_caches"].invoke
  end

end