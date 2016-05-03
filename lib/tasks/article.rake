require "#{Rails.root}/lib/importers/view_importer"
require "#{Rails.root}/lib/cleaners"
require "#{Rails.root}/lib/cleaners/revisions_cleaner"
require "#{Rails.root}/lib/importers/assigned_article_importer"

namespace :article do
  desc 'Calculate article views starting from the beginning of the course'
  task update_views_all_time: 'batch:setup_logger' do
    Rails.logger.debug 'Updating article views for all time'
    ViewImporter.update_all_views(true)
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
