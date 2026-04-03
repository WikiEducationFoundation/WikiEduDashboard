# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class ActiveCourseMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent to instructors mid-course to highlight student activity and progress.'
  METHOD_DESCRIPTIONS = {
    submission: 'Check-in email sent to an instructor whose course is actively running'
  }.freeze

  def submission
    ActiveCourseMailer.email(example_course, example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
