# frozen_string_literal: true

class OnboardingAlertManager
  def create_alert(user_name, msg)
    user = User.find_by(username: user_name)
    alert = Alert.create(type: 'OnboardingAlert',
                         user: user,
                         message: msg,
                         target_user: SpecialUsers.outreach_manager)
    alert.email_target_user
  end
end
