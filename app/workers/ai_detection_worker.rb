# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/check_revision_with_pangram"

class AiDetectionWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_check(wiki:, revision:, course:)
    # revision object is a RevisionOnMemory and sidekiq good practices
    # suggest keeping job parameters small, simple, and JSON-compatible
    attributes = { 'mw_rev_id' => revision.mw_rev_id,
                   'wiki_id' => wiki.id,
                   'article_id' => revision.article_id,
                   'course_id' => course.id,
                   'user_id' => revision.user_id,
                   'revision_timestamp' => revision.timestamp }
    perform_async(attributes)
  end

  def perform(attributes)
    CheckRevisionWithPangram.new(attributes)
  end
end
