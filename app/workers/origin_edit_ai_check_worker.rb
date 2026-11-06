# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/check_origin_edits_with_pangram"

class OriginEditAiCheckWorker
  include Sidekiq::Worker
  # CheckOriginEditsWithPangram swallows detector failures, so a retry only
  # follows a wiki or database failure, and reuses any scores already stored.
  sidekiq_options lock: :until_executed, retry: 3

  # The edit is still flagged, so it gets the regular AI edit alert when the
  # earlier edits could not be checked.
  sidekiq_retries_exhausted do |job, _exception|
    CheckOriginEditsWithPangram.new(job['args'].first, check_origins: false)
  end

  # attributes: the edit's 'mw_rev_id', 'wiki_id', 'article_id', 'course_id',
  # 'user_id' and 'article_title', plus 'parent_rev_id' and the pre-existing
  # flagged 'passages'
  def self.schedule(attributes)
    perform_async(attributes)
  end

  def perform(attributes)
    CheckOriginEditsWithPangram.new(attributes)
  end
end
