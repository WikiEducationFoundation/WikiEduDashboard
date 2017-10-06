# frozen_string_literal: true

class UntrainedStudentsAlertMailerPreview < ActionMailer::Preview
  def message_to_instructors
    UntrainedStudentsAlertMailer.email(UntrainedStudentsAlert.last)
  end
end
