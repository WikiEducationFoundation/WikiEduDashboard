# frozen_string_literal: true

class AlertMailerWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.schedule_email(alert_id:)
    perform_async(alert_id)
  end

  def perform(alert_id)
    alert = Alert.find(alert_id)
    alert.email_target_user
  end
end
