# frozen_string_literal: true

class CourseAdviceEmailWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_email(course:, subject:, send_at:)
    perform_at(send_at, course.id, subject)
  end

  def perform(course_id, subject)
    course = Course.find(course_id)
    # stop sending emails to courses that were withdrawn
    return unless course.approved?
    CourseAdviceMailer.send_email(course:, subject:)
  end
end
