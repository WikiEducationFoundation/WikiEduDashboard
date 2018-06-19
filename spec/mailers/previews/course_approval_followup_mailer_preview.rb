# frozen_string_literal: true

class CourseApprovalFollowupMailerPreview < ActionMailer::Preview
  def approval_followup
    CourseApprovalFollowupMailer.email(example_course, example_user, example_staffer)
  end

  private

  def example_course
    Course.new(
      slug: 'Example_University/Example_Course_(term)',
      passcode: 'abcdefg'
    )
  end

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end

  def example_staffer
    User.new(email: 'helaine@example.com', username: 'Helaine', real_name: 'Helaine Blumenthal')
  end
end
