# frozen_string_literal: true

require_dependency Rails.root.join('lib/alerts/overdue_training_alert_manager')

class OverdueTrainingAlertWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    OverdueTrainingAlertManager.new(Course.strictly_current).create_alerts
  end
end
