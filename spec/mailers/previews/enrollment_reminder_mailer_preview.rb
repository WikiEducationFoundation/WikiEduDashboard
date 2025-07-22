# frozen_string_literal: true

class EnrollmentReminderMailerPreview < ActionMailer::Preview
  def enrollment_reminder_email
    EnrollmentReminderMailer.email(example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
