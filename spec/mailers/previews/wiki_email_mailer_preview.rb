# frozen_string_literal: true

class WikiEmailMailerPreview < ActionMailer::Preview
  def email_warning
    WikiEmailMailer.email(user)
  end

  private

  def user
    User.first
  end
end
