# frozen_string_literal: true

class CourseApprovalMailer < ApplicationMailer
  def self.send_approval_notification(course, instructor)
    return unless Features.email? && Features.wiki_ed?
    return if instructor.email.nil?
    email(course, instructor).deliver_now
  end

  def email(course, instructor)
    @course = course
    @instructor = instructor
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @is_returning_instructor = @course.tag? 'returning_instructor'
    @enroll_link = "#{@course_link}?enroll=#{@course.passcode}"
    @signed = SpecialUsers.classroom_program_manager&.real_name || 'The Wiki Education team'
    # rubocop:disable Layout/LineLength
    mail(to: @instructor.email,
         subject: "Wiki Education — Your application for #{@course.title} / #{@course.term} at #{@course.school} has been approved!")
    # rubocop:enable Layout/LineLength
  end
end
