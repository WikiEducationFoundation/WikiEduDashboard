# frozen_string_literal: true

class CourseSubmissionMailerWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.schedule_email(course, instructor)
    perform_async(course.id, instructor.id)
  end

  def perform(course_id, instructor_id)
    course = Course.find(course_id)
    instructor = User.find(instructor_id)
    CourseSubmissionMailer.send_submission_confirmation(course, instructor)
    staffer = SpecialUsers.classroom_program_manager
    CourseSubmissionMailer.send_submission_confirmation(course, staffer) if staffer
  end
end
