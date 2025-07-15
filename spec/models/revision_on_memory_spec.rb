# frozen_string_literal: true

require 'rails_helper'

describe Revision, type: :model do
  describe '#references_added' do
    let(:reference_count_key) { 'num_ref' }
    let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }
    let(:wikidata_refs_tags_key) { 'feature.len(<datasource.wikidatawiki.revision.references>)' }
    let(:shortened_refs_tags_key) { 'feature.enwiki.revision.shortened_footnote_templates' }
    let(:enwikidata) { create(:wiki, project: 'wikidata', language: 'en') }

    before do
      stub_wiki_validation
    end

    context 'new article' do
      let(:mw_rev_id) { 95249249 }

      it 'returns zero' do
        revision = build(:revision_on_memory,
                         mw_rev_id:,
                         article_id: 45010238,
                         mw_page_id: 45010238)
        wikidata_revision = build(:revision_on_memory,
                                  mw_rev_id: 95249256,
                                  article_id: 36612,
                                  mw_page_id: 36612,
                                  wiki_id: enwikidata.id)
        expect(revision.references_added).to eq(0)
        expect(wikidata_revision.references_added).to eq(0)
      end
    end

    context 'First revision' do
      let(:mw_rev_id) { 857571904 }

      it 'returns no. of references added' do
        revision = build(:revision_on_memory,
                         mw_rev_id:,
                         article_id: 90010238,
                         mw_page_id: 90010238,
                         new_article: true,
                         features: {
                           refs_tags_key => 10
                         })
        wikidata_revision = build(:revision_on_memory,
                                  mw_rev_id: 840608564,
                                  article_id: 41155,
                                  mw_page_id: 41155,
                                  wiki_id: enwikidata.id,
                                  new_article: true,
                                  features: {
                                    wikidata_refs_tags_key => 10
                                  })
        expect(revision.references_added).to eq(10)
        expect(wikidata_revision.references_added).to eq(10)
      end
    end

    context 'Not the first revision, but previous revision data is not available' do
      let(:mw_rev_id) { 89023457 }

      it 'returns 0 references added' do
        revision = build(:revision_on_memory,
                         mw_rev_id:,
                         mw_page_id: 78240014,
                         article_id: 78240014,
                         new_article: false,
                         features: {
                           refs_tags_key => 10
                         })

        wikidata_revision = build(:revision_on_memory,
                                  mw_rev_id: 89023158,
                                  mw_page_id: 328439,
                                  article_id: 328439,
                                  wiki_id: enwikidata.id,
                                  new_article: false,
                                  features: {
                                    wikidata_refs_tags_key => 10
                                  })
        expect(revision.references_added).to eq(0)
        expect(wikidata_revision.references_added).to eq(0)
      end
    end

    context 'Deleted some references' do
      let(:mw_rev_id) { 852178130 }

      it 'Would be negative' do
        revision = build(:revision_on_memory,
                         mw_rev_id:,
                         article_id: 79010238,
                         mw_page_id: 79010238,
                         features: {
                           refs_tags_key => 0
                         },
                         features_previous: {
                           refs_tags_key => 6
                         })
        wikidata_revision = build(:revision_on_memory,
                                  mw_rev_id: 852178131,
                                  article_id: 320317,
                                  mw_page_id: 320317,
                                  wiki_id: enwikidata.id,
                                  features: {
                                    wikidata_refs_tags_key => 0
                                  },
                                  features_previous: {
                                    wikidata_refs_tags_key => 6
                                  })
        expect(revision.references_added).to eq(-6)
        expect(wikidata_revision.references_added).to eq(-6)
      end
    end

    context 'New refernces are added and not a new article' do
      let(:mw_rev_id) { 870348507 }

      it 'returns positive value' do
        revision = build(:revision_on_memory,
                         mw_rev_id:,
                         article_id: 55010239,
                         mw_page_id: 55010239,
                         features: {
                           refs_tags_key => 22
                         },
                         features_previous: {
                           refs_tags_key => 17
                         })
        wikidata_revision = build(:revision_on_memory,
                                  mw_rev_id: 870348508,
                                  article_id: 55010239,
                                  mw_page_id: 55010239,
                                  wiki_id: enwikidata.id,
                                  features: {
                                    wikidata_refs_tags_key => 22
                                  },
                                  features_previous: {
                                    wikidata_refs_tags_key => 17
                                  })
        expect(revision.references_added).to eq(5)
        expect(wikidata_revision.references_added).to eq(5)
      end
    end

    context 'has shortened footnote templates' do
      let(:mw_rev_id) { 902872698 }

      it 'includes the shortened footnote template references' do
        revision = build(:revision_on_memory,
                         mw_rev_id:,
                         article_id: 55012289,
                         mw_page_id: 55012289,
                         features: {
                           refs_tags_key => 4,
                           shortened_refs_tags_key => 131
                         },
                         features_previous: {
                           refs_tags_key => 0,
                           shortened_refs_tags_key => 1
                         })
        expect(revision.references_added).to eq(134)
      end
    end

    context 'has reference count key set as nil' do
      let(:mw_rev_id) { 902872698 }

      it 'uses the ref tag from Lift Wing API' do
        revision = build(:revision_on_memory,
                         mw_rev_id:,
                         article_id: 55012289,
                         mw_page_id: 55012289,
                         features: {
                           reference_count_key => nil,
                           refs_tags_key => 56
                         },
                         features_previous: {
                           reference_count_key => nil,
                           refs_tags_key => 7
                         })
        expect(revision.references_added).to eq(49)
      end
    end

    context 'has complete features' do
      let(:mw_rev_id) { 902872698 }

      it 'uses the reference count key from reference-counter API' do
        revision = build(:revision_on_memory,
                         mw_rev_id:,
                         article_id: 55012289,
                         mw_page_id: 55012289,
                         features: {
                           reference_count_key => 57,
                           refs_tags_key => 56,
                           shortened_refs_tags_key => 14
                         },
                         features_previous: {
                           reference_count_key => 6,
                           refs_tags_key => 7,
                           shortened_refs_tags_key => 1
                         })
        expect(revision.references_added).to eq(51)
      end
    end
  end
end
