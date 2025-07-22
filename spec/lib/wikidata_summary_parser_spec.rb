# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wikidata_summary_parser"

describe WikidataSummaryParser do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:create_claim_rev) { create(:revision, wiki: wikidata, mw_rev_id: 755333845) }
  let(:clear_item_rev) { create(:revision, wiki: wikidata, mw_rev_id: 996820366) }
  let(:deleted_rev) { create(:revision, wiki: wikidata, mw_rev_id: 968242606) }
  let(:unicode_summary_rev) { create(:revision, wiki: wikidata, mw_rev_id: 1297407522) }
  let(:revisions) { [create_claim_rev, clear_item_rev, deleted_rev, unicode_summary_rev] }

  before do
    stub_wiki_validation
    revisions
  end

  it 'imports and parses Wikidata summaries' do
    VCR.use_cassette 'wikidata_summaries' do
      ImportWikidataSummariesWorker.perform_async
    end
    analysis_output = described_class.analyze_revisions(Revision.all)
    expect(analysis_output['claims created']).to eq(1)
    expect(analysis_output['items cleared']).to eq(1)
    expect(analysis_output['descriptions added']).to eq(1)
  end
end
