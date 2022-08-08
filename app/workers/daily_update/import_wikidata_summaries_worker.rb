# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wikidata_summary_parser"

class ImportWikidataSummariesWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    wikidata = Wiki.get_or_create(language: nil, project: 'wikidata')
    Revision.where(wiki: wikidata, summary: nil, deleted: false).find_in_batches do |revision_batch|
      revision_batch.each do |rev|
        summary = WikidataSummaryParser.fetch_summary(rev)
        next if summary.nil?
        begin
          rev.update!(summary:)
        rescue ActiveRecord::StatementInvalid => e
          Sentry.capture_exception e
          rev.update(summary: CGI.escape(summary))
        end
      end
    end
  end
end
