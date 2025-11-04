# frozen_string_literal: true

class AiEditAlertMailerPreview < ActionMailer::Preview
  def ai_edit_alert
    AiEditAlertMailer.email(example_alert)
  end

  private

  def example_alert
    AiEditAlert.where.not(article: nil).last
  end
end
