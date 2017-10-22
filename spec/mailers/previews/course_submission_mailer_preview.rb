# frozen_string_literal: true

class CourseSubmissionMailerPreview < ActionMailer::Preview
  def submission
    CourseSubmissionMailer.email(Course.last, example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
