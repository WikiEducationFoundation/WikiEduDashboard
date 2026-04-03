# frozen_string_literal: true

class WikiEmailMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Warning sent when a user has a public Wikipedia email address configured.'
  METHOD_DESCRIPTIONS = {
    email_warning: 'Warns the user that their Wikipedia email is public and may receive spam'
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
