namespace :article do

  desc 'Update all articles'
  task :update_articles => :environment do
    Rails.logger.info "Updating all articles"
    Article.update_all_articles
  end

  desc 'Update article views incrementally'
  task :update_views => :environment do
    Rails.logger.info "Updating article views"
    Article.update_all_views
  end

  desc 'Calculate article views starting from the beginning of the course'
  task :update_views_all_time => :environment do
    Rails.logger.info "Updating article views for all time"
    Article.update_all_views(true)
  end

end