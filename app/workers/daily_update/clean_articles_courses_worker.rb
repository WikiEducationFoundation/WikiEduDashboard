# frozen_string_literal: true

require_dependency Rails.root.join('lib/articles_courses_cleaner')

class CleanArticlesCoursesWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    ArticlesCoursesCleaner.rebuild_articles_courses
  end
end
