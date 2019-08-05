# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/articles_courses_cleaner"

class CleanArticlesCoursesWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    ArticlesCoursesCleaner.rebuild_articles_courses
  end
end
