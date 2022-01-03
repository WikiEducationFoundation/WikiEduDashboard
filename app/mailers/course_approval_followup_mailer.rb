# frozen_string_literal: true

class CourseApprovalFollowupMailer < ApplicationMailer
  def self.send_followup(course)
    return unless Features.email?
    return unless course.instructors.pluck(:email).any?
    staffer = SpecialUsers.classroom_program_manager
    email(course, staffer).deliver_now
  end

  def email(course, staffer)
    @course = course
    @instructors = @course.instructors
    @staffer = staffer
    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @enroll_link = "#{@course_link}?enroll=#{@course.passcode}"
    mail(to: @instructors.pluck(:email),
         reply_to: @staffer.email,
         subject: 'Tips for beginning your Wikipedia assignment')
  end
end
