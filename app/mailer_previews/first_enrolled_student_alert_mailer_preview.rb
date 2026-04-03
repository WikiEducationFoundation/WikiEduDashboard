# frozen_string_literal: true

class FirstEnrolledStudentAlertMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent to instructors when the very first student enrolls in their course.'
  METHOD_DESCRIPTIONS = {
    message_to_instructors: 'Congratulatory alert to instructors when their first student joins'
  }.freeze

  def message_to_instructors
    FirstEnrolledStudentAlertMailer.email(alert)
  end

  private

  def alert
    FirstEnrolledStudentAlert.new(course: example_course)
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
