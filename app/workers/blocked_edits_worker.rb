# frozen_string_literal: true

require "#{Rails.root}/lib/blocked_edits_monitor"

class BlockedEditsWorker
  include Sidekiq::Worker

  def self.schedule_notifications(user:)
    perform_async(user.id)
  end

  def perform(user_id)
    blocked_user = User.find(user_id)
    BlockedEditsMonitor.create_alerts_for_blocked_edits(blocked_user)
  end
end
