# frozen_string_literal: true

require_dependency Rails.root.join('lib/alerts/blocked_edits_reporter')

class BlockedEditsWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_notifications(user:, response_data:)
    perform_async(user.id, response_data)
  end

  def perform(user_id, response_data)
    blocked_user = User.find(user_id)
    BlockedEditsReporter.create_alerts_for_blocked_edits(blocked_user, response_data)
  end
end
