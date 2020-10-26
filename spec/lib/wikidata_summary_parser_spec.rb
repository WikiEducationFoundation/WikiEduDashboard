# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wikidata_summary_parser"

describe WikidataSummaryParser do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:create_claim_rev) { create(:revision, wiki: wikidata, mw_rev_id: 755333845) }
  let(:clear_item_rev) { create(:revision, wiki: wikidata, mw_rev_id: 996820366) }
  let(:revisions) { [create_claim_rev, clear_item_rev] }

  before { stub_wiki_validation }

  it 'imports and parses Wikidata summaries' do
    VCR.use_cassette 'wikidata_summaries' do
      revisions.each { |r| r.update(summary: described_class.fetch_summary(r)) }
    end
    analysis_output = described_class.analyze_revisions(revisions)
    expect(analysis_output['claims created']).to eq(1)
    expect(analysis_output['items cleared']).to eq(1)
  end
end
