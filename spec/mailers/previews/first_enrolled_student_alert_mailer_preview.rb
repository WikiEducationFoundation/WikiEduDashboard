# frozen_string_literal: true

class FirstEnrolledStudentAlertMailerPreview < ActionMailer::Preview
  def message_to_instructors
    FirstEnrolledStudentAlertMailer.email(alert)
  end

  private

  def alert
    FirstEnrolledStudentAlert.new(course: Course.nonprivate.last)
  end
end
