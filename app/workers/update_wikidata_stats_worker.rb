# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/update_wikidata_stats"

class UpdateWikidataStatsWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  retry: 0

  def self.update_course(course_id:, queue:)
    UpdateWikidataStatsWorker.set(queue: queue).perform_async(course_id)
  end

  def perform(course_id)
    course = Course.find(course_id)
    UpdateWikidataStats.new(course)
  rescue StandardError => e
    Sentry.capture_exception e
  end
end
