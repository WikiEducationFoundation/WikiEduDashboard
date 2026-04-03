# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/instructor_notification

require_relative 'mailer_preview_helpers'

class InstructorNotificationPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Admin-authored notification emails sent directly to all instructors in a course.'
  METHOD_DESCRIPTIONS = {
    message_to_instructors: 'Custom notification from an admin to all course instructors'
  }.freeze
  RECIPIENTS = 'instructor(s)'

  def message_to_instructors
    InstructorNotificationMailer.email(example_alert, true)
  end

  private

  def example_alert
    InstructorNotificationAlert.new(type: 'InstructorNotificationAlert',
                                    course: example_course,
                                    message: 'Hello from Admin, This
                                    is a test notification!',
                                    user_id: 1,
                                    subject: 'Test Subject')
  end
end
