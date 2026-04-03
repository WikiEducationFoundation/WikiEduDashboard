# frozen_string_literal: true

class EnrollmentReminderMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Reminder sent to students who have not yet enrolled in their Wikipedia course.'
  METHOD_DESCRIPTIONS = {
    enrollment_reminder_email: 'Prompts a student to complete enrollment via the course passcode'
  }.freeze

  def enrollment_reminder_email
    EnrollmentReminderMailer.email(example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
