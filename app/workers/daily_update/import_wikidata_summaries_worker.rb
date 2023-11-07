# frozen_string_literal: true

require_dependency Rails.root.join('lib/importers/wikidata_summary_importer')

class ImportWikidataSummariesWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    WikidataSummaryImporter.new.import_all_missing_summaries
  end
end
