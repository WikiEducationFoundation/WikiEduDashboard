# frozen_string_literal: true

class CourseApprovalMailer < ApplicationMailer
  def self.send_approval_notification(course, instructor)
    return unless Features.email?
    return if instructor.email.nil?
    email(course, instructor).deliver_now
  end

  def email(course, instructor)
    @course = course
    @instructor = instructor
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @enroll_link = "#{@course_link}?enroll=#{@course.passcode}"
    mail(to: @instructor.email,
         subject: "Your Wiki Ed course page for #{@course.title} has been approved")
  end
end
