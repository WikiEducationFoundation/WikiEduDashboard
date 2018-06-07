# frozen_string_literal: true

class OverdueTrainingAlertMailerPreview < ActionMailer::Preview
  def message_to_student
    OverdueTrainingAlertMailer.email(OverdueTrainingAlert.last)
  end
end
