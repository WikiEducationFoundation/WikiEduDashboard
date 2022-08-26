# frozen_string_literal: true

class WikiEmailMailerPreview < ActionMailer::Preview
  def email_warning
    WikiEmailMailer.email(example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
