namespace :batch do

  desc 'Pull all new data from sources and store appropriately'

  task :update_all => :environment do
    Rake::Task["course:update_courses"].invoke

    Rake::Task["revision:update_revisions"].invoke

    Rake::Task["cache:update_caches"].invoke
  end

end