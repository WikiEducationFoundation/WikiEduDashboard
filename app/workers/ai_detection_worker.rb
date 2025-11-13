# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/check_revision_with_pangram"

class AiDetectionWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_check(wiki:, revision:, course:)
    perform_async(wiki.id, revision.mw_rev_id, revision.user_id, course.id, revision.date.to_i)
  end

  def perform(wiki_id, mw_rev_id, user_id, course_id, rev_date)
    CheckRevisionWithPangram.new(wiki_id, mw_rev_id, user_id, course_id, rev_date)
  end
end
