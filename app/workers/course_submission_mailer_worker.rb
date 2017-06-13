# frozen_string_literal: true

class CourseSubmissionMailerWorker
  include Sidekiq::Worker

  def self.schedule_email(course, instructor)
    perform_async(course.id, instructor.id)
  end

  def perform(course_id, instructor_id)
    course = Course.find(course_id)
    instructor = User.find(instructor_id)
    CourseSubmissionMailer.send_submission_confirmation(course, instructor)
    staffer = User.find_by(username: ENV['classroom_program_manager'])
    CourseSubmissionMailer.send_submission_confirmation(course, staffer) if staffer
  end
end
