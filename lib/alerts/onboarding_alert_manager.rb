# frozen_string_literal: true

class OnboardingAlertManager
  def create_alert(user_name, msg, details)
    user = User.find_by(username: user_name)
    alert = Alert.create(type: 'OnboardingAlert',
                         user:,
                         message: msg,
                         details:,
                         target_user: SpecialUsers.outreach_manager)
    alert.email_target_user
  end
end
