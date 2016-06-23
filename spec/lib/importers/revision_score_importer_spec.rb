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
           mw_page_id: 45010238)
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
  end

  it 'saves wp10 scores for revisions' do
    VCR.use_cassette 'revision_scores/by_revisions' do
      RevisionScoreImporter.new.update_revision_scores
      early_score = Revision.find_by(mw_rev_id: 641962088).wp10.to_f
      later_score = Revision.find_by(mw_rev_id: 675892696).wp10.to_f
      expect(early_score).to be > 0
      expect(later_score).to be > early_score
    end
  end

  it 'saves wp10 scores by article' do
    VCR.use_cassette 'revision_scores/by_article' do
      articles = Article.all
      RevisionScoreImporter.new
                           .update_all_revision_scores_for_articles(articles)
      early_score = Revision.find_by(mw_rev_id: 46745264).wp10.to_f
      later_score = Revision.find_by(mw_rev_id: 662106477).wp10.to_f
      expect(early_score).to be > 0
      expect(later_score).to be > early_score
    end
  end

  it 'does not try to query deleted revisions' do
    revisions = RevisionScoreImporter.new.send(:unscored_mainspace_userspace_and_draft_revisions)
    expect(revisions.where(mw_rev_id: 1).count).to eq(0)
  end

  it 'handles network errors gracefully' do
    stub_request(:any, %r{https://ores.wikimedia.org/.*})
      .to_raise(Errno::ECONNREFUSED)
    RevisionScoreImporter.new.update_revision_scores(Revision.all)
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
      RevisionScoreImporter.new.update_revision_scores
    end
  end
end
