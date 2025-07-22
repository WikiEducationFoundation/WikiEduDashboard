# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/wikidata_summary_importer"

describe WikidataSummaryImporter do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:create_claim_rev) { create(:revision, wiki: wikidata, mw_rev_id: 755333845) }
  let(:clear_item_rev) { create(:revision, wiki: wikidata, mw_rev_id: 996820366) }
  let(:deleted_rev) { create(:revision, wiki: wikidata, mw_rev_id: 968242606) }
  let(:unicode_summary_rev) { create(:revision, wiki: wikidata, mw_rev_id: 1297407522) }
  let(:same_page_revision_1) { create(:revision, wiki: wikidata, mw_rev_id: 10012) }
  let(:same_page_revision_2) { create(:revision, wiki: wikidata, mw_rev_id: 10016) }
  let(:revisions) do
    [create_claim_rev, clear_item_rev, deleted_rev, unicode_summary_rev,
     same_page_revision_1, same_page_revision_2]
  end

  before do
    stub_wiki_validation
    revisions
  end

  it 'handles encoding problems gracefully' do
    VCR.use_cassette 'wikidata_summaries' do
      ImportWikidataSummariesWorker.perform_async
    end

    expect(unicode_summary_rev.reload.summary).not_to be nil
    # Only the deleted rev should lack a summary
    expect(Revision.where(summary: nil).count).to eq(1)
    expect(Revision.where.not(summary: nil).count).to eq(5)
  end
end
