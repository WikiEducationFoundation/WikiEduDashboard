# frozen_string_literal: true

class NoTaEnrolledAlertMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent when a course requires a teaching assistant but none has enrolled.'
  METHOD_DESCRIPTIONS = {
    message_to_instructors: 'Prompts instructors to recruit or enroll a teaching assistant'
  }.freeze

  def message_to_instructors
    NoTaEnrolledAlertMailer.email(example_alert)
  end

  private

  def example_alert
    Alert.new(type: 'NoTaEnrolledAlert', course: example_course)
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
