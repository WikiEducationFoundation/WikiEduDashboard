# frozen_string_literal: true
require_dependency "#{Rails.root}/app/services/update_course_revisions"

class CourseDataUpdateWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.update_course(course_id:, queue:)
    CourseDataUpdateWorker.set(queue: queue).perform_async(course_id)
  end

  def perform(course_id)
    course = Course.find(course_id)
    UpdateCourseRevisions.new(course)
  end
end
