# frozen_string_literal: true

class AlertMailerWorker
  include Sidekiq::Worker

  def self.schedule_email(alert)
    perform_async(alert.id, alert.target_user.id)
  end

  def perform(alert_id, user_id)
    alert = Alert.find(alert_id)
    user  = User.find(user_id)

    AlertMailer.alert(alert, user).deliver_now
    alert.update_attribute(:email_sent_at, Time.now)
  end
end
