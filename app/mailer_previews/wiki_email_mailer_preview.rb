# frozen_string_literal: true

class WikiEmailMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Warning when a user has not set up email on their Wikipedia account.'
  METHOD_DESCRIPTIONS = {
    email_warning: 'Warns the user that they might not be able to reset their password'
  }.freeze
  RECIPIENTS = 'user'

  def email_warning
    WikiEmailMailer.email(example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
