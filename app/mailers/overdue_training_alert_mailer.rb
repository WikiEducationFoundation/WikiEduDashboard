# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training_module"

class OverdueTrainingAlertMailer < ApplicationMailer
  def email(alert)
    return unless Features.email?
    @alert = alert
    user_email = @alert.user.email
    return if user_email.blank?

    params = { to: user_email,
               subject: @alert.main_subject }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end
end
