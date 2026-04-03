# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class NoTaEnrolledAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent when a course requires a teaching assistant but none has enrolled.'
  METHOD_DESCRIPTIONS = {
    message_to_instructors: 'Prompts instructors to recruit or enroll a teaching assistant'
  }.freeze

  def message_to_instructors
    NoTaEnrolledAlertMailer.email(example_alert)
  end

  private

  def example_alert
    Alert.new(type: 'NoTaEnrolledAlert', course: example_course)
  end
end
