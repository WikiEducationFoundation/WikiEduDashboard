require 'rails_helper'
require "#{Rails.root}/lib/importers/revision_score_importer"

describe RevisionScoreImporter do
  before do
    create(:article,
           id: 45010238,
           title: 'Manspreading',
           namespace: 0)
    create(:revision,
           id: 675892696, # latest revision as of 2015-08-19
           article_id: 45010238)
    create(:revision,
           id: 641962088, # first revision, barely a stub
           article_id: 45010238)

    create(:article,
           id: 1538038,
           title: 'Performativity',
           namespace: 0)
    create(:revision,
           id: 662106477, # revision from 2015-05-13
           article_id: 1538038)
    create(:revision,
           id: 46745264, # revision from 2006-04-03
           article_id: 1538038)
  end

  it 'should save wp10 scores for revisions' do
    VCR.use_cassette 'revision_scores/by_revisions' do
      pending 'This should pass unless ORES is down or overloaded.'

      RevisionScoreImporter.update_revision_scores
      early_score = Revision.find(641962088).wp10.to_f
      later_score = Revision.find(675892696).wp10.to_f
      expect(early_score).to be > 0
      expect(later_score).to be > early_score

      puts 'PASSED'
      fail 'this test passed — this time'
    end
  end

  it 'should save wp10 scores by article' do
    VCR.use_cassette 'revision_scores/by_article' do
      pending 'This should pass unless ORES is down or overloaded.'

      article_ids = [45010238, 1538038]
      RevisionScoreImporter
        .update_all_revision_scores_for_articles(article_ids)
      early_score = Revision.find(46745264).wp10.to_f
      later_score = Revision.find(662106477).wp10.to_f
      expect(early_score).to be > 0
      expect(later_score).to be > early_score

      puts 'PASSED'
      fail 'this test passed — this time'
    end
  end

  it 'should handle network errors gracefully' do
    stub_request(:any, %r{https://ores.wmflabs.org/.*})
      .to_raise(Errno::ECONNREFUSED)
    RevisionScoreImporter.update_revision_scores(Revision.all)
    expect(Revision.find(662106477).wp10).to be_nil
  end
end
