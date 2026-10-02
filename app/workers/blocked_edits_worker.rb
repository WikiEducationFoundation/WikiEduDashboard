# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/alerts/blocked_edits_reporter"

class BlockedEditsWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_notifications(user:, response_data:, wiki: nil)
    perform_async(user.id, response_data, wiki&.id)
  end

  def perform(user_id, response_data, wiki_id = nil)
    blocked_user = User.find(user_id)
    wiki = Wiki.find_by(id: wiki_id)
    BlockedEditsReporter.create_alerts_for_blocked_edits(blocked_user, response_data, wiki)
  end
end
