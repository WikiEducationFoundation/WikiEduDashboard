# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class BlockedStudentAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent when a student Wikipedia account is blocked from editing.'
  RECIPIENTS = 'student, instructor(s), Wiki Expert'

  def blocked_student_alert
    BlockedUserAlertMailer.email(example_blocked_alert)
  end

  private

  def example_blocked_alert
    Alert.new(type: 'BlockedUserAlert', user: example_instructor, course: example_course)
  end
end
