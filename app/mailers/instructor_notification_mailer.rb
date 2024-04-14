# frozen_string_literal: true

class InstructorNotificationMailer < ApplicationMailer
  def self.send_email(alert)
    return unless Features.email?
    email(alert).deliver_now
  end

  def email(alert)
    @alert = alert
    set_email_parameters
    params = { to: @instructors.pluck(:email),
               subject: @alert.subject,
               bcc: [
                 @alert.sender_email,
                 @alert.bcc_to_salesforce_email
               ] }
    params[:reply_to] = @alert.sender_email unless @alert.sender_email.nil?
    mail(params)
  end

  private

  def set_email_parameters
    @course = @alert.course
    @subject = @alert.subject
    @instructors = @course.instructors
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @message = @alert.message
  end
end
