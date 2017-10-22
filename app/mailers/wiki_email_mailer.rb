# frozen_string_literal: true

class WikiEmailMailer < ApplicationMailer
  def self.send_email_warning(user)
    return unless Features.email? && Features.wiki_ed?
    return if user.email.nil?
    email(user).deliver_now
  end

  def email(user)
    @user = user
    mail(to: @user.email, subject: 'Your Wikipedia email settings')
  end
end
