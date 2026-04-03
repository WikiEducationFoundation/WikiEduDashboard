# frozen_string_literal: true

class UntrainedStudentsAlertMailerPreview < ActionMailer::Preview
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
