namespace :article do
  desc 'Update article views incrementally'
  task update_views: :environment do
    Rails.logger.info 'Updating article views'
    Article.update_all_views
  end

  desc 'Calculate article views starting from the beginning of the course'
  task update_views_all_time: :environment do
    Rails.logger.info 'Updating article views for all time'
    Article.update_all_views(true)
  end

  desc 'Update views for newly added articles'
  task update_new_article_views: :environment do
    Rails.logger.info 'Updating views for newly added articles'
    Article.update_new_views
  end

  desc 'Update ratings for all articles'
  task update_ratings: :environment do
    Rails.logger.info 'Updating article ratings'
    Article.update_all_ratings
  end
end
