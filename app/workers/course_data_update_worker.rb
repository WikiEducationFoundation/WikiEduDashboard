# frozen_string_literal: true
require_dependency "#{Rails.root}/app/services/update_course_stats"

class CourseDataUpdateWorker
  THIRTY_DAYS = 60 * 60 * 24 * 30
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  unique_expiration: THIRTY_DAYS,
                  retry: 0 # Move job to the 'dead' queue if it fails

  def self.update_course(course_id:, queue:)
    CourseDataUpdateWorker.set(queue: queue).perform_async(course_id)
  end

  def perform(course_id)
    course = Course.find(course_id)
    UpdateCourseStats.new(course)
  rescue StandardError => e
    Raven.capture_exception e
  end
end
