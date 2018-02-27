# frozen_string_literal: true

class HeardFromAlertManager
  def create_alert(user_name, msg)
    user = User.find_by(username: user_name)
    unless Alert.exists?(user_id: user.id, type: 'HeardFromAlert')
      alert = Alert.create(type: 'HeardFromAlert',
                           user: user,
                           message: msg,
                           target_user: SpecialUsers.outreach_manager)
      alert.email_target_user
    end
  end
end
