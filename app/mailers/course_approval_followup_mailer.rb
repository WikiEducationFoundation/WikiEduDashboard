# frozen_string_literal: true

class CourseApprovalFollowupMailer < ApplicationMailer
  def self.send_followup(course, instructor)
    return unless Features.email?
    return if instructor.email.nil?
    staffer = SpecialUsers.classroom_program_manager
    email(course, instructor, staffer).deliver_now
  end

  def email(course, instructor, staffer)
    @course = course
    @instructor = instructor
    @staffer = staffer
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @enroll_link = "#{@course_link}?enroll=#{@course.passcode}"
    mail(to: @instructor.email,
         reply_to: @staffer.email,
         subject: 'Tips for beginning your Wikipedia assignment')
  end
end
