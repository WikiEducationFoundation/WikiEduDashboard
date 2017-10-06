# frozen_string_literal: true

class NoEnrolledStudentsAlertMailerPreview < ActionMailer::Preview
  def message_to_instructors
    NoEnrolledStudentsAlertMailer.email(NoEnrolledStudentsAlert.last)
  end
end
