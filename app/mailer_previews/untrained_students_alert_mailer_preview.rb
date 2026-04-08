# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class UntrainedStudentsAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent when a significant portion of students are behind on assigned trainings.'
  METHOD_DESCRIPTIONS = {
    message_to_instructors: 'Tells instructors how many students are untrained'
  }.freeze
  RECIPIENTS = 'instructor(s)'

  def message_to_instructors
    UntrainedStudentsAlertMailer.email(example_alert)
  end

  private

  def example_alert
    UntrainedStudentsAlert.new(course: example_course)
  end
end
