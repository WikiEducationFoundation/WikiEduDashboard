# frozen_string_literal: true

class ActiveCourseMailerPreview < ActionMailer::Preview
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
