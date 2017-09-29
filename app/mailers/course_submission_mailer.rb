# frozen_string_literal: true

class CourseSubmissionMailer < ApplicationMailer
  def self.send_submission_confirmation(course, instructor)
    return unless Features.email?
    return if instructor.email.nil?
    email(course, instructor).deliver_now
  end

  def email(course, instructor)
    @course = course
    @instructor = instructor
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    mail(to: @instructor.email, subject: 'Thanks for submitting your course!')
  end
end
