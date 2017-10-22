# frozen_string_literal: true

class AlertMailer < ApplicationMailer
  def alert(alert, recipient)
    return unless Features.email?
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
