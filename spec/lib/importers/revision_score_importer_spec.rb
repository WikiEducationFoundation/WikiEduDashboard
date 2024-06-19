# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/revision_score_importer"

describe RevisionScoreImporter do
  let(:array_revisions) { [] }

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
    array_revisions << create(:revision,
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
    array_revisions << create(:revision,
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
    create(:article,
           id: 456,
           mw_page_id: 49505160,
           title: 'Philip_James_Rutledge',
           namespace: 0)
    array_revisions << create(:revision, # deleted revision
                              mw_rev_id: 708326238,
                              article_id: 456,
                              mw_page_id: 49505160)
    create(:article,
           id: 678,
           mw_page_id: 123456,
           title: 'Premi_O_Premi',
           namespace: 0)

    array_revisions << create(:revision, # deleted revision
                              mw_rev_id: 753277075,
                              article_id: 678,
                              mw_page_id: 123456)
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
      expect(later_revision.features['num_ref']).to eq(13)
    end
  end

  it 'marks TextDeleted revisions as deleted' do
    VCR.use_cassette 'revision_scores/deleted_revision' do
      # See https://ores.wikimedia.org/v2/scores/enwiki/wp10/708326238?features
      # https://en.wikipedia.org/wiki/Philip_James_Rutledge?diff=708326238
      article = Article.find(456)
      described_class.new.update_revision_scores
      revision = article.revisions.first
      expect(revision.deleted).to eq(true)
      expect(revision.wp10).to be_nil
      expect(revision.features).to eq({})
    end
  end

  it 'marks RevisionNotFound revisions as deleted' do
    VCR.use_cassette 'revision_scores/deleted_revision' do
      article = Article.find(678)
      described_class.new.update_revision_scores
      revision = article.revisions.first
      expect(revision.deleted).to eq(true)
      expect(revision.wp10).to be_nil
      expect(revision.features).to eq({})
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
    revision = Revision.find_by(mw_rev_id: 662106477)
    expect(revision.wp10).to be_nil
    expect(revision.features).to eq({})
    expect(revision.deleted).to eq(false)

    stub_request(:any, %r{https://api.wikimedia.org/service/lw/.*})
      .to_raise(Errno::ECONNREFUSED)

    stub_request(:any, /.*reference-counter.toolforge.org*/)
      .to_raise(Errno::ECONNREFUSED)

    described_class.new.update_revision_scores

    # no value changed for the revision
    revision = Revision.find_by(mw_rev_id: 662106477)
    expect(revision.wp10).to be_nil
    expect(revision.features).to eq({})
    expect(revision.deleted).to eq(false)
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

  describe '#get_revision_scores' do
    it 'returns empty array if no revisions' do
      revisions = described_class.new.get_revision_scores([])
      expect(revisions).to eq([])
    end

    it 'updates wp10 scores and features for revisions' do
      VCR.use_cassette 'revision_scores/get_revision_scores' do
        revisions = described_class.new.get_revision_scores(array_revisions)

        # updates wp10
        expect(revisions[0].features['num_ref']).to eq(0)
        expect(revisions[1].features['num_ref']).to eq(9)

        # updates features
        expect(revisions[0].wp10.to_f).to be >= 11
        expect(revisions[1].wp10.to_f).to be >= 36
      end
    end

    it 'updates wp10 previous scores and features previous for non-first revisions' do
      VCR.use_cassette 'revision_scores/get_revision_scores' do
        revisions = described_class.new.get_revision_scores(array_revisions)

        # updates wp10 previous
        expect(revisions[1].wp10_previous).to be >= 46

        # updates features previous
        expect(revisions[1].features_previous['num_ref']).to eq(9)
      end
    end

    it 'does not try to query previous revisions for first revision' do
      # This spec makes sense because get_parent_revisions calls non_new_revisions
      # to filter the revision before querying parent revisions for them
      revisions = described_class.new.send(:non_new_revisions, array_revisions)
      # non-first revision 641962088 is discarded
      expect(revisions).to eq([662106477, 708326238, 753277075])
    end

    it 'wp10 previous scores and features previous is nil for first revisions' do
      VCR.use_cassette 'revision_scores/get_revision_scores' do
        revisions = described_class.new.get_revision_scores(array_revisions)

        # wp10 previous keeps being nil
        expect(revisions[0].wp10_previous).to be_nil

        # features previous keep being nil
        expect(revisions[0].features_previous).to eq({})
      end
    end

    it 'marks TextDeleted revisions as deleted' do
      VCR.use_cassette 'revision_scores/deleted_revision' do
        # See https://ores.wikimedia.org/v2/scores/enwiki/wp10/708326238?features
        # https://en.wikipedia.org/wiki/Philip_James_Rutledge?diff=708326238
        revisions = described_class.new.get_revision_scores(array_revisions)
        expect(revisions[2].deleted).to eq(true)
        expect(revisions[2].wp10).to be_nil
        expect(revisions[2].features).to eq({})
      end
    end

    it 'marks RevisionNotFound revisions as deleted' do
      VCR.use_cassette 'revision_scores/deleted_revision' do
        revisions = described_class.new.get_revision_scores(array_revisions)
        expect(revisions[3].deleted).to eq(true)
        expect(revisions[3].wp10).to be_nil
        expect(revisions[3].features).to eq({})
      end
    end

    it 'handles network errors gracefully' do
      stub_request(:any, %r{https://api.wikimedia.org/service/lw/.*})
        .to_raise(Errno::ECONNREFUSED)

      stub_request(:any, /.*reference-counter.toolforge.org*/)
        .to_raise(Errno::ECONNREFUSED)

      revisions = described_class.new.get_revision_scores(array_revisions)

      # no value changed for the revisions
      expect(revisions).to eq(array_revisions)
    end
  end
end
