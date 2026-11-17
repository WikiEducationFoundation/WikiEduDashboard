# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class CourseApplicationMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  METHOD_DESCRIPTIONS = {
    accepted: 'Acceptance email for applicants',
    declined: 'Decline email for applicants'
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
    # The body is each course's own staff-written text.
    course.build_course_application_form(
      acceptance_email: "[the course's acceptance email, written by staff in its " \
                        'application form settings]'
    )
    CourseApplication.new(course:, user: example_instructor)
  end
end
