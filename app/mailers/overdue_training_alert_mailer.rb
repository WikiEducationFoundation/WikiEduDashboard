# frozen_string_literal: true

class OverdueTrainingAlertMailer < ApplicationMailer
  def self.send_email(alert)
    return unless Features.email?
    return if alert.user.email.blank?
    email(alert).deliver_now
    alert.update(email_sent_at: Time.zone.now)
  rescue Mailgun::CommunicationError => e
    Sentry.capture_exception e, extra: { username: alert.user.username,
                                         email: alert.user.email }
  end

  def email(alert)
    @alert = alert
    @course_url = @alert.url
    @days_until_next_alert = OverdueTrainingAlert::MINIMUM_DAYS_BETWEEN_ALERTS
    params = { to: @alert.user.email,
               subject: @alert.main_subject }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end
end
