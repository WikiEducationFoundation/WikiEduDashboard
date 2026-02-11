# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/check_revision_with_pangram"

class AiDetectionWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_check(wiki:, revision:, course:)
    # Sidekiq good practices suggest keeping job parameters small, simple, and JSON-compatible.
    # We pass IDs and integer timestamps instead of objects or hashes with symbol keys.
    perform_async(revision.mw_rev_id, wiki.id, revision.article_id, course.id, revision.user_id, revision.timestamp)
  end

  def perform(mw_rev_id, wiki_id, article_id, course_id, user_id, revision_timestamp)
    attributes = {
      'mw_rev_id' => mw_rev_id,
      'wiki_id' => wiki_id,
      'article_id' => article_id,
      'course_id' => course_id,
      'user_id' => user_id,
      'revision_timestamp' => revision_timestamp
    }
    CheckRevisionWithPangram.new(attributes)
  end
end
