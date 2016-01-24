require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/importers/view_importer"
require "#{Rails.root}/lib/importers/rating_importer"
require "#{Rails.root}/lib/cleaners"
require "#{Rails.root}/lib/revisions_cleaner"
require "#{Rails.root}/lib/importers/assigned_article_importer"

namespace :article do
  desc 'Update article views incrementally'
  task update_views: 'batch:setup_logger' do
    Rails.logger.debug 'Updating article views'
    ViewImporter.update_all_views
  end

  desc 'Calculate article views starting from the beginning of the course'
  task update_views_all_time: 'batch:setup_logger' do
    Rails.logger.debug 'Updating article views for all time'
    ViewImporter.update_all_views(true)
  end

  desc 'Update views for newly added articles'
  task update_new_article_views: 'batch:setup_logger' do
    Rails.logger.debug 'Updating views for newly added articles'
    ViewImporter.update_new_views
  end

  desc 'Update ratings for all articles'
  task update_all_ratings: 'batch:setup_logger' do
    Rails.logger.debug 'Updating ratings for all articles'
    RatingImporter.update_all_ratings
  end

  desc 'Update ratings for new articles'
  task update_new_ratings: 'batch:setup_logger' do
    Rails.logger.debug 'Updating ratings for new articles'
    RatingImporter.update_new_ratings
  end

  desc 'Update deleted status for all articles'
  task update_article_status: 'batch:setup_logger' do
    Rails.logger.debug 'Updating article namespace and deleted status'
    ArticleStatusManager.update_article_status
  end

  # These tasks are intended for ad-hoc use to resolve problems
  # introduced by old, bad logic
  desc 'Remove botched ArticlesCourses'
  task reset_articles_courses: 'batch:setup_logger' do
    Rails.logger.debug 'Removing messed up ArticlesCourses'
    Cleaners.remove_bad_articles_courses
  end

  desc 'Rebuild ArticlesCourses based on all Revisions'
  task rebuild_articles_courses: 'batch:setup_logger' do
    Rails.logger.debug 'Rebuilding ArticlesCourses for all current students'
    Cleaners.rebuild_articles_courses
  end

  desc 'Find articles for orphaned revisions'
  task repair_orphan_revisions: 'batch:setup_logger' do
    Rails.logger.debug 'Repairing orphaned revisions'
    RevisionsCleaner.repair_orphan_revisions
  end

  desc 'Import assigned articles'
  task import_assigned_articles: 'batch:setup_logger' do
    Rails.logger.debug 'Finding articles that match assignment titles'
    AssignedArticleImporter.import_articles_for_assignments
  end
end
