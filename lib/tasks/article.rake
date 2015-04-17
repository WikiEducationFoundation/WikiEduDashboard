namespace :article do
  desc 'Update article views incrementally'
  task update_views: "batch:setup_logger" do
    Rails.logger.info 'Updating article views'
    Article.update_all_views
  end

  desc 'Calculate article views starting from the beginning of the course'
  task update_views_all_time: "batch:setup_logger" do
    Rails.logger.info 'Updating article views for all time'
    Article.update_all_views(true)
  end

  desc 'Update views for newly added articles'
  task update_new_article_views: "batch:setup_logger" do
    Rails.logger.debug 'Updating views for newly added articles'
    Article.update_new_views
  end

  desc 'Update ratings for all articles'
  task update_all_ratings: "batch:setup_logger" do
    Rails.logger.info 'Updating ratings for all articles'
    Article.update_all_ratings
  end

  desc 'Update ratings for new articles'
  task update_new_ratings: "batch:setup_logger" do
    Rails.logger.debug 'Updating ratings for new articles'
    Article.update_new_ratings
  end

  desc 'Update deleted status for all articles'
  task update_articles_deleted: "batch:setup_logger" do
    Rails.logger.info 'Updating article deleted status'
    Article.update_articles_deleted
  end

  # This task is intended for ad-hoc use, should be removed ASAP
  desc 'Remove botched ArticlesCourses'
  task reset_articles_courses: "batch:setup_logger" do
    Rails.logger.info 'Removing messed up ArticlesCourses'
    ArticlesCourses.remove_bad_articles_courses
  end
end
