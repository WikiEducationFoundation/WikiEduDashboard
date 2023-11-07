# frozen_string_literal: true

require_dependency Rails.root.join('app/services/update_wikidata_stats')

class UpdateWikidataStatsWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  retry: 0

  def perform(course)
    UpdateWikidataStats.new(course)
  end
end
