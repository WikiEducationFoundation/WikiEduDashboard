# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/check_origin_edits_with_pangram"

class OriginEditAiCheckWorker
  include Sidekiq::Worker
  # CheckOriginEditsWithPangram swallows detector failures, so a retry only
  # follows a wiki or database failure, and reuses any scores already stored.
  sidekiq_options lock: :until_executed, retry: 3

  def self.schedule(ai_edit_alert:, parent_rev_id:, passages:)
    perform_async(ai_edit_alert.id, parent_rev_id, passages)
  end

  def perform(ai_edit_alert_id, parent_rev_id, passages)
    ai_edit_alert = AiEditAlert.find_by(id: ai_edit_alert_id)
    return if ai_edit_alert.nil?

    CheckOriginEditsWithPangram.new(ai_edit_alert:, parent_rev_id:, passages:)
  end
end
