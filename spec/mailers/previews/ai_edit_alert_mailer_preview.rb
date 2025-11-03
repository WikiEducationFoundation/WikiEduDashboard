# frozen_string_literal: true

class AiEditAlertMailerPreview < ActionMailer::Preview
  def ai_edit_alert
    AiEditAlertMailer.email(example_alert, page_repeat: false, user_repeat: false)
  end

  def ai_edit_alert_same_user
    AiEditAlertMailer.email(example_alert, page_repeat: false, user_repeat: true)
  end

  def ai_edit_alert_same_page
    AiEditAlertMailer.email(example_alert, page_repeat: true, user_repeat: false)
  end

  private

  def example_alert
    AiEditAlert.last
  end
end
