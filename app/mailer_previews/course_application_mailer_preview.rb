# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class CourseApplicationMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = '[PLACEHOLDER - one-line description of the Scholars & Scientists application decision emails]' # rubocop:disable Layout/LineLength
  METHOD_DESCRIPTIONS = {
    accepted: '[PLACEHOLDER - label for the acceptance email preview]',
    declined: '[PLACEHOLDER - label for the decline email preview]'
  }.freeze
  RECIPIENTS = 'applicant'

  def accepted
    CourseApplicationMailer.accepted(example_application)
  end

  def declined
    CourseApplicationMailer.declined(example_application)
  end

  private

  def example_application
    course = FellowsCohort.new(title: 'Wiki Scholars: Elections and Voting',
                               slug: 'Wiki_Education/Elections_and_Voting_(Spring_2027)')
    course.build_course_application_form(
      acceptance_email: '[PLACEHOLDER - sample acceptance email for the preview]'
    )
    CourseApplication.new(course:, user: example_instructor)
  end
end
