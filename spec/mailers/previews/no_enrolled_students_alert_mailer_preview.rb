# frozen_string_literal: true

class NoEnrolledStudentsAlertMailerPreview < ActionMailer::Preview
  def message_to_instructors
    NoEnrolledStudentsAlertMailer.email(example_alert)
  end

  private

  def example_alert
    Alert.new(type: 'NoEnrolledStudentsAlert', course: Course.nonprivate.last)
  end
end
