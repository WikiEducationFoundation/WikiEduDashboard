# frozen_string_literal: true

class AlertMailer < ApplicationMailer
  def self.send_alert_email(alert, recipient)
    return unless Features.email?
    alert(alert, recipient).deliver_now
  end

  def alert(alert, recipient)
    @recipient = recipient
    @alert = alert
    @type = @alert.type
    @article = @alert.article
    @message = @alert.message
    @resolvable = @alert.resolvable?
    @details = @alert.details
    params = { to: @recipient.email,
               subject: "#{@type}: #{@alert.main_subject}" }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end
end
