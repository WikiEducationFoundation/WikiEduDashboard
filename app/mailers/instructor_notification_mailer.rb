# frozen_string_literal: true

class InstructorNotificationMailer < ApplicationMailer
  def self.send_email(alert, bcc_to_salesforce)
    return unless Features.email?
    email(alert, bcc_to_salesforce).deliver_now
  end

  def email(alert, bcc_to_salesforce: true)
    @alert = alert
    set_email_parameters
    params = { to: @instructors.pluck(:email),
               subject: @alert.subject,
               bcc: bcc_to_salesforce ? ENV['SALESFORCE_BCC_EMAIL'] : nil }
    return if params[:to].empty?
    params[:from] = @alert.sender_email unless @alert.sender_email.nil?
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
