# frozen_string_literal: true

class NoTaEnrolledAlertMailerPreview < ActionMailer::Preview
  def message_to_instructors
    NoTaEnrolledAlertMailer.email(example_alert)
  end

  private

  def example_alert
    Alert.new(type: 'NoTaEnrolledAlert', course: Course.nonprivate.last)
  end
end
