# frozen_string_literal: true

class ActiveCourseMailerPreview < ActionMailer::Preview
  def submission
    ActiveCourseMailer.email(Course.nonprivate.last, example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
