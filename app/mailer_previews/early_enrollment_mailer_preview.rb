# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/early_enrollment_mailer

require_relative 'mailer_preview_helpers'

class EarlyEnrollmentMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent when students enroll unusually early before a course starts.'
  METHOD_DESCRIPTIONS = {
    message_to_wiki_experts: 'Notifies Wiki Experts of early enrollment for proactive outreach'
  }.freeze
  RECIPIENTS = 'Wiki Expert'

  def message_to_wiki_experts
    EarlyEnrollmentMailer.email(example_alert)
  end

  private

  def example_alert
    EarlyEnrollmentAlert.new(type: 'EarlyEnrollmentAlert', course: example_course)
  end
end
