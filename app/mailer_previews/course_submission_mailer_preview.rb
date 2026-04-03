# frozen_string_literal: true

class CourseSubmissionMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent to Wiki Ed staff when an instructor submits a course for review.'
  METHOD_DESCRIPTIONS = {
    submission: 'Staff notification email triggered when an instructor submits their course'
  }.freeze

  def submission
    CourseSubmissionMailer.email(example_course, example_user)
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
