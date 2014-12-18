namespace :article do

  desc 'Update the data for current-term articles'

  task :update_articles => :environment do
    Rails.logger.info "Updating all articles"
    Article.update_all_articles
  end

  task :update_article_views => :environment do
    # Implement method for updating all article views
  end

end