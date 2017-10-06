# frozen_string_literal: true

class CourseApprovalMailerPreview < ActionMailer::Preview
  def approval
    CourseApprovalMailer.email(example_course, example_user)
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
end
