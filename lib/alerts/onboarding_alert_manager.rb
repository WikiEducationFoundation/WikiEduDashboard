# frozen_string_literal: true

class OnboardingAlertManager
  def create_alert(user_name, msg)
    user = User.find_by(username: user_name)
    unless Alert.exists?(user_id: user.id, type: 'OnboardingAlert')
      alert = Alert.create(type: 'OnboardingAlert',
                           user: user,
                           message: "Heard about Wiki Edu from: #{msg}",
                           target_user: SpecialUsers.outreach_manager)
      alert.email_target_user
    end
  end
end
