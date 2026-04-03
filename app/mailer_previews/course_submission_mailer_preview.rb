# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class CourseSubmissionMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent to Wiki Ed staff when an instructor submits a course for review.'
  METHOD_DESCRIPTIONS = {
    submission: 'Staff notification email triggered when an instructor submits their course'
  }.freeze
  RECIPIENTS = 'staff'

  def submission
    CourseSubmissionMailer.email(example_course, example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
