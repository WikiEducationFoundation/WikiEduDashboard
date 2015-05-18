require "#{Rails.root}/lib/importers/article_importer"

namespace :article do
  desc 'Update article views incrementally'
  task update_views: "batch:setup_logger" do
    Rails.logger.debug 'Updating article views'
    ArticleImporter.update_all_views
  end

  desc 'Calculate article views starting from the beginning of the course'
  task update_views_all_time: "batch:setup_logger" do
    Rails.logger.debug 'Updating article views for all time'
    ArticleImporter.update_all_views(true)
  end

  desc 'Update views for newly added articles'
  task update_new_article_views: "batch:setup_logger" do
    Rails.logger.debug 'Updating views for newly added articles'
    ArticleImporter.update_new_views
  end

  desc 'Update ratings for all articles'
  task update_all_ratings: "batch:setup_logger" do
    Rails.logger.debug 'Updating ratings for all articles'
    ArticleImporter.update_all_ratings
  end

  desc 'Update ratings for new articles'
  task update_new_ratings: "batch:setup_logger" do
    Rails.logger.debug 'Updating ratings for new articles'
    ArticleImporter.update_new_ratings
  end

  desc 'Update deleted status for all articles'
  task update_article_status: "batch:setup_logger" do
    Rails.logger.debug 'Updating article namespace and deleted status'
    ArticleImporter.update_article_status
  end



  # These tasks are intended for ad-hoc use to resolve problems
  # introduced by old, bad logic
  desc 'Remove botched ArticlesCourses'
  task reset_articles_courses: "batch:setup_logger" do
    Rails.logger.debug 'Removing messed up ArticlesCourses'
    ArticleImporter.remove_bad_articles_courses
  end

  desc 'Rebuild ArticlesCourses based on all Revisions'
  task rebuild_articles_courses: "batch:setup_logger" do
    Rails.logger.debug 'Rebuilding ArticlesCourses from all Revisions'
    ArticlesCourses.update_from_revisions
  end
end
