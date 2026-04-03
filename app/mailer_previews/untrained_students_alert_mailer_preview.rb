# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class UntrainedStudentsAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent when students in a course have not completed required Wikipedia training.'
  METHOD_DESCRIPTIONS = {
    message_to_instructors: 'Tells instructors how many students are untrained'
  }.freeze

  def message_to_instructors
    UntrainedStudentsAlertMailer.email(example_alert)
  end

  private

  def example_alert
    UntrainedStudentsAlert.new(course: example_course)
  end
end
