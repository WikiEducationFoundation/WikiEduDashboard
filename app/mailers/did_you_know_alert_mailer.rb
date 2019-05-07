# frozen_string_literal: true

class DidYouKnowAlertMailer < ApplicationMailer
  def self.send_dyk_email(alert)
    return unless Features.email?
    email(alert).deliver_now
  end

  def email(alert)
    @alert = alert
    set_course_and_recipients
    return if @recipients.empty?
    params = { to: @recipients,
             subject: @alert.main_subject }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end

  private

  def set_course_and_recipients
    @course = @alert.course
    @recipients = @course.instructors.pluck(:email) +
                  @course.nonstudents.where(greeter: true).pluck(:email)
  end
end
