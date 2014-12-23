namespace :article do

  desc 'Update the data for current-term articles'

  task :update_articles => :environment do
    Rails.logger.info "Updating all articles"
    Article.update_all_articles
  end

end