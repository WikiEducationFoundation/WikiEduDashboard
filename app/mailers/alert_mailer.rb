# frozen_string_literal: true
class AlertMailer < ApplicationMailer
  def alert(alert, recipient)
    return unless Features.email?
    @recipient = recipient
    @alert = alert
    @type = @alert.type
    @article = @alert.article
    @message = @alert.message
    mail(to: @recipient.email, subject: "#{@type}: #{@alert.main_subject}")
  end
end
