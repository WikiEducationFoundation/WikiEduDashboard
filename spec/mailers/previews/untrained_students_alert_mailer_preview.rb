# frozen_string_literal: true

class UntrainedStudentsAlertMailerPreview < ActionMailer::Preview
  def message_to_instructors
    UntrainedStudentsAlertMailer.email(example_alert)
  end

  private

  def example_alert
    UntrainedStudentsAlert.new(course: Course.nonprivate.last)
  end
end
