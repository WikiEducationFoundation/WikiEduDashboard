# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class TermRecapMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'End-of-term summary emails sent to instructors after their course finishes.'
  METHOD_DESCRIPTIONS = {
    email_to_instructors: 'Full recap with stats for courses with strong student contributions',
    basic_email_to_instructors: 'Shorter recap for courses with lower average word counts'
  }.freeze
  RECIPIENTS = 'instructor(s)'

  def email_to_instructors
    TermRecapMailer.email(example_course, Campaign.default_campaign)
  end

  def basic_email_to_instructors
    TermRecapMailer.basic_email(example_course, Campaign.default_campaign)
  end
end
