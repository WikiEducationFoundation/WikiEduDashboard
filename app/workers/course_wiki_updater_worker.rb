# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

class CourseWikiUpdaterWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_deletion(course:, wiki_ids:)
    perform_async(course.id, wiki_ids)
  end

  def perform(course_id, wiki_ids)
    course = Course.find(course_id)
    # Be sure the courses wikis were deleted
    current_course_wiki_ids = course.courses_wikis(&:wiki_id)
    deleted_wiki_ids = wiki_ids - current_course_wiki_ids
    # Deletes timeslices for the deleted wikis
    TimesliceManager.new(course).delete_timeslices_for_deleted_course_wikis deleted_wiki_ids
    # Deletes articles courses
    ArticlesCoursesCleanerTimeslice.remove_bad_articles_courses(course, deleted_wiki_ids)
  end
end
