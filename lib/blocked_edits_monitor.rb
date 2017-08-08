# frozen_string_literal: true

class BlockedEditsMonitor
  def self.create_alerts_for_blocked_edits(user)
    new.create_alert(user)
  end

  def create_alert(user)
    return if alert_already_exists?
    alert = Alert.create!(type: 'BlockedEditsAlert',
                          user_id: user.id,
                          target_user_id: technical_help_staff&.id)
    alert.email_target_user
  end

  def alert_already_exists?
    Alert.exists?(['created_at >= ? AND type = ?',
                   (Time.now - (8 * 60 * 60)).to_s,
                   'BlockedEditsAlert'])
  end

  private

  def technical_help_staff
    User.find_by(username: ENV['technical_help_staff'])
  end
end
