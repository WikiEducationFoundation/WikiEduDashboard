# frozen_string_literal: true

class AiEditAlertMailerPreview < ActionMailer::Preview
  def student_program_ai_edit_alert
    AiEditAlertMailer.email(example_alert)
  end

  def scholars_program_ai_edit_alert
    AiEditAlertMailer.email(example_scholars_alert)
  end

  private

  def example_alert
    AiEditAlert.where.not(article: nil).last
  end

  def example_scholars_alert
    AiEditAlert.new(
      course: FellowsCohort.last,
      user: example_alert.user,
      article: example_alert.article,
      revision_id: example_alert.revision_id,
      details: example_alert.details
    )
  end
end
