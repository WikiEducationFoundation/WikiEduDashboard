# frozen_string_literal: true

class UnsubmittedCourseAlertMailerPreview < ActionMailer::Preview
  def message_to_instructor
    UnsubmittedCourseAlertMailer.email(alert)
  end

  private

  def alert
    user = User.first
    Alert.new(type: 'UnsubmittedCourseAlert',
              course: Course.new(slug: 'Example_University/Example_Course_(term)'),
              user:,
              target_user: user)
  end
end
