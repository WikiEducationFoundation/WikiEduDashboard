namespace :article do

  desc 'Update the data for current-term articles'

  task :update_articles => :environment do
    Rails.logger.info "Updating all articles"
    Article.update_all_articles
  end

  # Update article views
  task :update_views => :environment do
    Rails.logger.info "Updating article views"
    Article.update_all_views
  end

  # Update article views
  task :update_views_all_time => :environment do
    Rails.logger.info "Updating article views for all time"
    Article.update_all_views(true)
  end

end