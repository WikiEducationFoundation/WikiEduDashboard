# frozen_string_literal: true

class CourseApprovalFollowupMailer < ApplicationMailer
  def self.send_followup(course)
    return unless Features.email?
    return unless course.instructors.pluck(:email).any?
    staffer = SpecialUsers.classroom_program_manager
    instructors = course.instructors
    email(course, staffer, instructors).deliver_now
  end

  def email(course, staffer, instructors)
    @course = course
    @staffer = staffer
    @greeted_users = instructors.map { |user| user.real_name || user.username }.to_sentence
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    locale_param = @course.campaigns.first&.default_language
    @enroll_link = "#{@course_link}?enroll=#{@course.passcode}"
    @enroll_link += "&locale=#{locale_param}" if locale_param.present?
    mail(to: instructors.map(&:email),
         reply_to: @staffer.email,
         subject: 'Tips for beginning your Wikipedia assignment')
  end
end
