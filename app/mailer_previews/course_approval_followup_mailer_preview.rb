# frozen_string_literal: true

class CourseApprovalFollowupMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Automatically sent a few days after a course is approved by Wiki Education staff.'
  METHOD_DESCRIPTIONS = {
    approval_followup: 'Personal follow-up introducing the Wiki Ed staffer to the instructor'
  }.freeze
  RECIPIENTS = 'instructor(s)'

  def approval_followup
    CourseApprovalFollowupMailer.email(example_course, example_staffer, example_instructors)
  end

  private

  def example_course
    Course.new(
      slug: 'Example_University/Example_Course_(term)',
      passcode: 'abcdefg'
    )
  end

  def example_instructors
    [User.new(email: 'sage@example.com', username: 'Ragesoss')]
  end

  def example_staffer
    User.new(email: 'helaine@example.com', username: 'Helaine', real_name: 'Helaine Blumenthal')
  end
end
