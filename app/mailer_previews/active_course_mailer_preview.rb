# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class ActiveCourseMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent to instructors mid-course to highlight student activity and progress.'
  METHOD_DESCRIPTIONS = {
    submission: 'Active course mailer (based on average words-added in live articles)'
  }.freeze
  RECIPIENTS = 'instructor(s)'

  def submission
    ActiveCourseMailer.email(example_course, example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
