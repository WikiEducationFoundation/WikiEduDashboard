# frozen_string_literal: true

class UnsubmittedCourseAlertMailerPreview < ActionMailer::Preview
  def message_to_instructor
    UnsubmittedCourseAlertMailer.email(alert)
  end

  private

  def alert
    Alert.new(type: 'UnsubmittedCourseAlert',
              course: Course.new(slug: 'Example_University/Example_Course_(term)'),
              user: example_user,
              target_user: example_user)
  end

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
