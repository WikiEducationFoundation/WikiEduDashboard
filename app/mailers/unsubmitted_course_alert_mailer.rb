# frozen_string_literal: true

class UnsubmittedCourseAlertMailer < ApplicationMailer
  def self.send_email(alert)
    return if !alert.user || alert.user.email.blank?
    email(alert).deliver_now
  end

  def email(alert)
    @instructor = alert.user
    @name = @instructor.real_name || @instructor.username
    @course_url = "https://#{ENV['dashboard_url']}/courses/#{alert.course.slug}"
    @classroom_program_manager = SpecialUsers.classroom_program_manager
    subject = 'Reminder: Submit your Wiki Education course page'
    mail(to: @instructor.email,
         reply_to: @classroom_program_manager&.email,
         subject:)
  end
end
