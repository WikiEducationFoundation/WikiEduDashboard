# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class FirstEnrolledStudentAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent to instructors when the very first student enrolls in their course.'
  METHOD_DESCRIPTIONS = {
    message_to_instructors: 'Congratulatory alert to instructors when their first student joins'
  }.freeze

  def message_to_instructors
    FirstEnrolledStudentAlertMailer.email(alert)
  end

  private

  def alert
    FirstEnrolledStudentAlert.new(course: example_course)
  end
end
