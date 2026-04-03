# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/early_enrollment_mailer

class EarlyEnrollmentMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent when students enroll unusually early before a course starts.'
  METHOD_DESCRIPTIONS = {
    message_to_wiki_experts: 'Notifies Wiki Experts of early enrollment for proactive outreach'
  }.freeze

  def message_to_wiki_experts
    EarlyEnrollmentMailer.email(example_alert)
  end

  private

  def example_alert
    EarlyEnrollmentAlert.new(type: 'EarlyEnrollmentAlert', course: example_course)
  end

  def example_course
    Course.new(
      title: 'Advanced Topics in Global Health',
      slug: 'Global_Health/Advanced_Topics_(Spring_2025)',
      school: 'University of Maryland',
      expected_students: 24,
      user_count: 22,
      start: 3.months.ago,
      end: 1.month.from_now,
      revision_count: 450
    )
  end
end
