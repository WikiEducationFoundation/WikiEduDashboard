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
        expect(revisions[2].error).to eq(false)
      end
    end

    it 'marks RevisionNotFound revisions as deleted' do
      VCR.use_cassette 'revision_scores/notfound_revision' do
        revisions = described_class.new.get_revision_scores(array_revisions)
        expect(revisions[3].deleted).to eq(true)
        expect(revisions[3].wp10).to be_nil
        expect(revisions[3].features).to eq({})
        expect(revisions[3].error).to eq(false)
      end
    end

    it 'propagates error if fetching revision scores fails' do
      VCR.use_cassette 'revision_scores/revision_score_fails' do
        stub_request(:any, /reference-counter\.toolforge\.org.*662106477/)
          .to_raise(Errno::ECONNREFUSED)

        revisions = described_class.new.get_revision_scores(array_revisions)
        expect(revisions[0].error).to eq(false)
        expect(revisions[1].error).to eq(true)
        expect(revisions[2].error).to eq(false)
        expect(revisions[3].error).to eq(false)
      end
    end

    it 'propagates error if fetching parent revision scores fails' do
      VCR.use_cassette 'revision_scores/parent_revision_score_fails' do
        stub_request(:any, /reference-counter\.toolforge\.org.*708291784/)
          .to_raise(Errno::ECONNREFUSED)

        revisions = described_class.new.get_revision_scores(array_revisions)
        expect(revisions[0].error).to eq(false)
        expect(revisions[1].error).to eq(false)
        expect(revisions[2].error).to eq(true)
        expect(revisions[3].error).to eq(false)
      end
    end

    it 'handles network errors gracefully when reference-counter fails' do
      stub_request(:any, /.*reference-counter.toolforge.org*/)
        .to_raise(Errno::ECONNREFUSED)

      revisions = described_class.new.get_revision_scores(array_revisions)
      expect(revisions[0].error).to eq(true)
    end

    it 'handles network errors gracefully when lift wing API fails' do
      stub_request(:any, %r{https://api.wikimedia.org/service/lw/.*})
        .to_raise(Errno::ECONNREFUSED)

      revisions = described_class.new.get_revision_scores(array_revisions)
      expect(revisions[0].error).to eq(true)
    end
  end
end
