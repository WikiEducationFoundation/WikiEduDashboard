# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/articles_courses_cleaner"

class CleanArticlesCoursesWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    # TODO: think how to clean articles courses without persisted revisions
    # ArticlesCoursesCleaner.rebuild_articles_courses
  end
end
