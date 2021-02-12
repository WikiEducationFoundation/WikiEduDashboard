# frozen_string_literal: true

class CourseAdviceEmailWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.schedule_email(course:, stage:, send_at:)
    perform_at(send_at, course.id, stage)
  end

  def perform(course_id, stage)
    course = Course.find(course_id)
    CourseAdviceMailer.send_email(course: course, stage: stage)
  end
end
