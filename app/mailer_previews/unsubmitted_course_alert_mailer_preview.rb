# frozen_string_literal: true

class UnsubmittedCourseAlertMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent when an instructor has not submitted their course draft for approval.'
  METHOD_DESCRIPTIONS = {
    message_to_instructor: 'Nudges the instructor to submit their course before the start date'
  }.freeze

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
