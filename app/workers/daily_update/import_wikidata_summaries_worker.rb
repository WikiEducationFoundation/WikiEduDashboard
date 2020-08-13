# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wikidata_summary_parser"

class ImportWikidataSummariesWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    wikidata = Wiki.get_or_create(language: nil, project: 'wikidata')
    Revision.where(wiki: wikidata, summary: nil).find_in_batches do |revision_batch|
      revision_batch.each do |rev|
        rev.update(summary: WikidataSummaryParser.fetch_summary(rev))
      end
    end
  end
end
