# frozen_string_literal: true

class EnrollmentReminderMailer < ApplicationMailer
  def self.send_reminder(user)
    return unless Features.email? && Features.wiki_ed?
    return if user.email.nil?
    email(user).deliver_now
  end

  def email(user)
    @user = user
    mail(to: @user.email, subject: 'Next steps on Wiki Education Dashboard')
  end
end
