# frozen_string_literal: true

class NoTaEnrolledAlertMailer < ApplicationMailer
  def self.send_email(alert)
    return unless Features.email?
    email(alert).deliver_now
  end

  # def email(alert)
  #   @alert = alert
  #   params = {}
  #   mail(params)
  # end
end
