# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/revision_score_importer"

describe RevisionScoreImporter do
  before do
    create(:article,
           id: 45010238,
           mw_page_id: 45010238,
           title: 'Manspreading',
           namespace: 0)
    create(:revision,
           mw_rev_id: 675892696, # latest revision as of 2015-08-19
           article_id: 45010238,
           mw_page_id: 45010238)
    create(:revision,
           mw_rev_id: 641962088, # first revision, barely a stub
           article_id: 45010238,
           mw_page_id: 45010238,
           new_article: true)
    create(:revision,
           mw_rev_id: 1, # arbitrary deleted revision
           deleted: true,
           article_id: 45010238,
           mw_page_id: 45010238)

    create(:article,
           id: 1538038,
           mw_page_id: 1538038,
           title: 'Performativity',
           namespace: 0)
    create(:revision,
           mw_rev_id: 662106477, # revision from 2015-05-13
           article_id: 1538038,
           mw_page_id: 1538038)
    create(:revision,
           mw_rev_id: 46745264, # revision from 2006-04-03
           article_id: 1538038,
           mw_page_id: 1538038)
    create(:revision,
           mw_rev_id: 777777777, # does not exist
           article_id: 1538038,
           mw_page_id: 1538038)
  end

  it 'saves wp10 scores and features for revisions' do
    VCR.use_cassette 'revision_scores/by_revisions' do
      described_class.new.update_revision_scores
      early_revision = Revision.find_by(mw_rev_id: 641962088)
      later_revision = Revision.find_by(mw_rev_id: 675892696)
      early_score = early_revision.wp10.to_f
      later_score = later_revision.wp10.to_f
      expect(early_score).to be_between(0, 100)
      expect(later_score).to be_between(early_score, 100)
      expect(later_revision.features['feature.wikitext.revision.external_links']).to eq(12)
    end
  end

  it 'saves wp10 scores by article' do
    VCR.use_cassette 'revision_scores/by_article' do
      described_class.update_revision_scores_for_all_wikis
    end

    all_score = Revision.all.map(&:wp10)
    expect(all_score.count).to be_positive
    all_previous_score = Revision.all.map(&:wp10_previous)
    all_score.each do |sc|
      expect(sc || 0).to be_between(0, 100)
    end
    all_previous_score.each do |sc|
      expect(sc || 0).to be_between(0, 100)
    end
  end

  it 'marks TextDeleted revisions as deleted' do
    VCR.use_cassette 'revision_scores/deleted_revision' do
      # See https://ores.wikimedia.org/v2/scores/enwiki/wp10/708326238?features
      # https://en.wikipedia.org/wiki/Philip_James_Rutledge?diff=708326238
      article = create(:article,
                       mw_page_id: 49505160,
                       title: 'Philip_James_Rutledge',
                       namespace: 0)
      create(:revision,
             mw_rev_id: 708326238,
             article_id: article.id,
             mw_page_id: 49505160)
      described_class.new.update_revision_scores
      revision = article.revisions.first
      expect(revision.deleted).to eq(true)
      expect(revision.wp10).to be_nil
      expect(revision.features).to be_empty
    end
  end

  it 'marks RevisionNotFound revisions as deleted' do
    VCR.use_cassette 'revision_scores/deleted_revision' do
      # Article and its revisions are deleted
      article = create(:article,
                       mw_page_id: 123456,
                       title: 'Premi_O_Premi',
                       namespace: 0)
      create(:revision,
             mw_rev_id: 753277075,
             article_id: article.id,
             mw_page_id: 123456)
      described_class.new.update_revision_scores
      revision = article.revisions.first
      expect(revision.deleted).to eq(true)
      expect(revision.wp10).to be_nil
      expect(revision.features).to be_empty
    end
  end

  it 'does not try to query deleted revisions' do
    revisions = described_class.new.send(:unscored_revisions)
    expect(revisions.where(mw_rev_id: 1).count).to eq(0)
  end

  it 'does not try to query previous revisions for first revision' do
    revisions = described_class.new.send(:unscored_previous_revisions)
    expect(revisions.where(mw_rev_id: 641962088).count).to eq(0)
  end

  it 'handles network errors gracefully' do
    stub_request(:any, %r{https://api.wikimedia.org/service/lw/.*})
      .to_raise(Errno::ECONNREFUSED)
    described_class.new.update_revision_scores
    expect(Revision.find_by(mw_rev_id: 662106477).wp10).to be_nil
  end

  # This probably represents buggy behavior from ores.
  it 'handles revisions that return an array' do
    VCR.use_cassette 'revision_scores/array_bug' do
      create(:article,
             id: 1,
             mw_page_id: 1,
             title: 'Foo',
             namespace: 2)
      create(:revision,
             article_id: 1,
             mw_rev_id: 712439107)
      # see https://ores.wmflabs.org/v1/scores/enwiki/wp10/?revids=712439107
      described_class.new.update_revision_scores
    end
  end

  describe '#update_previous_revision_scores' do
    it 'saves the wp10_previous score for a set of revisions' do
      VCR.use_cassette 'revision_scores/wp10_previous' do
        expect(Revision.find_by(mw_rev_id: 662106477).wp10_previous).to be_nil
        expect(Revision.find_by(mw_rev_id: 46745264).wp10_previous).to be_nil
        described_class.new.update_previous_revision_scores
        expect(Revision.find_by(mw_rev_id: 662106477).wp10_previous).to be_between(0, 100)
        expect(Revision.find_by(mw_rev_id: 46745264).wp10_previous).to be_between(0, 100)
      end
    end
  end

  describe '#fetch_ores_data_for_revision_id' do
    let(:rev_id) { 860858080 }
    # https://en.wikipedia.org/w/index.php?title=Hamlin_Park&oldid=860858080
    # https://www.wikidata.org/w/index.php?title=Q61734980&oldid=860858080
    let(:language) { 'en' }
    let(:project) { 'wikipedia' }
    let(:subject) do
      described_class.new(language:, project:)
                     .fetch_ores_data_for_revision_id(rev_id)
    end

    it 'returns a hash with a predicted rating and features' do
      VCR.use_cassette 'revision_scores/single_revision' do
        expect(subject[:features]).to have_key('feature.wikitext.revision.wikilinks')
        expect(subject[:rating]).to eq('Stub')
      end
    end

    context 'for Wikidata revisions' do
      let(:language) { nil }
      let(:project) { 'wikidata' }

      it 'returns a hash with features' do
        VCR.use_cassette 'revision_scores/single_revision' do
          expect(subject[:features]).to have_key(Revision::WIKIDATA_REFERENCES)
          expect(subject[:rating]).to eq('D')
        end
      end
    end
  end

  describe '.update_revision_scores_for_all_wikis' do
    let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }

    before do
      stub_wiki_validation
      LiftWingApi::AVAILABLE_WIKIPEDIAS.each do |lang|
        wiki = Wiki.get_or_create(language: lang, project: 'wikipedia')
        article = create(:article, wiki:)
        create(:revision, article:, wiki:, mw_rev_id: 1234)
      end
      wikidata_item = create(:article, wiki: wikidata)
      create(:revision, article: wikidata_item, wiki: wikidata, mw_rev_id: 12345)
    end

    it 'imports data and calcuates an article completeness score for available wikis' do
      pending 'This sometimes fails, likely because of rate limiting. We should look into it.'

      VCR.use_cassette 'revision_scores/multiwiki' do
        described_class.update_revision_scores_for_all_wikis

        LiftWingApi::AVAILABLE_WIKIPEDIAS.each do |lang|
          wiki = Wiki.get_or_create(language: lang, project: 'wikipedia')
          # This is fragile, because it assumes every available wiki has an existing
          # revision 1234. But it works so far.
          expect(wiki.revisions.first.wp10).to be_between(0, 100)
        end

        expect(wikidata.revisions.first.features).not_to be_empty
      end

      pass_pending_spec
    end
  end

  context 'for a wiki without the articlequality model' do
    it 'raises an error' do
      stub_wiki_validation
      expect { described_class.new(language: 'zh').update_revision_scores }
        .to raise_error(LiftWingApi::InvalidProjectError)
    end
  end
end
