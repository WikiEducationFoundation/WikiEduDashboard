# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class NoEnrolledStudentsAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent when a course approaches its start date with no students enrolled.'
  METHOD_DESCRIPTIONS = {
    message_to_instructors: 'Prompts instructors to share the enrollment link before course starts'
  }.freeze
  RECIPIENTS = 'instructor(s)'

  def message_to_instructors
    NoEnrolledStudentsAlertMailer.email(example_alert)
  end

  private

  def example_alert
    Alert.new(type: 'NoEnrolledStudentsAlert', course: example_course)
  end
end
