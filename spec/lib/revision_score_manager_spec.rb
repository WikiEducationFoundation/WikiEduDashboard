# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/revision_score_manager"

describe RevisionScoreManager do
  let(:article) { create(:article, mw_page_id: 12345) }
  let(:course) { create(:course, start: '2023-01-01', end: '2023-02-01') }
  let(:manager) { described_class.new(article, course) }

  describe '#within_revision_limit?' do
    it 'returns true if no ArticlesCourses record exists' do
      allow(ArticlesCourses).to receive(:find_by).and_return(nil)
      expect(manager.within_revision_limit?).to be true
    end

    it 'returns true if revision_count is under 500' do
      # Create a double that specifically responds to revision_count
      article_course = double('ArticlesCourses', revision_count: 100)
      allow(ArticlesCourses).to receive(:find_by).and_return(article_course)
      
      expect(manager.within_revision_limit?).to be true
    end

    it 'returns false if revision_count is 500 or more' do
      # Create a double that specifically responds to revision_count
      article_course = double('ArticlesCourses', revision_count: 501)
      allow(ArticlesCourses).to receive(:find_by).and_return(article_course)
      
      expect(manager.within_revision_limit?).to be false
    end
  end


  describe '#fetch_scored_revisions' do
    let(:wiki_api_response) do
      {
        'query' => {
          'pages' => {
            '12345' => {
              'revisions' => [
                { 'revid' => 101, 'user' => 'RageSock', 'timestamp' => '2023-01-10T12:00:00Z', 
'size' => 1000 },
                { 'revid' => 102, 'user' => 'WikiedStaff', 'timestamp' => '2023-01-11T12:00:00Z', 
'size' => 1100 }
              ]
            }
          }
        }
      }
    end

    let(:lift_wing_scores) do
      {
        '101' => { 'wp10' => 0.5 }
      }
    end

    before do
      # Mock WikiApi
      allow_any_instance_of(WikiApi).to receive(:query).and_return(wiki_api_response)
      # Mock LiftWingApi
      allow_any_instance_of(LiftWingApi).to receive(:get_revision_data).and_return(lift_wing_scores)
    end

    it 'returns formatted data only for enrolled users' do
      enrolled_usernames = ['RageSock','MillerWon']
      result = manager.fetch_scored_revisions(enrolled_usernames)

      expect(result.length).to eq(1)
      expect(result.first[:rev_id]).to eq(101)
      expect(result.first[:username]).to eq('RageSock')
      expect(result.first[:wp10]).to eq(0.5)
    end

    it 'returns an empty array if no revisions match enrolled users' do
      enrolled_usernames = ['MillerWon']
      result = manager.fetch_scored_revisions(enrolled_usernames)
      expect(result).to eq([])
    end

    it 'handles cases where ORES/LiftWing scores are missing' do
      allow_any_instance_of(LiftWingApi).to receive(:get_revision_data).and_return({})
      enrolled_usernames = ['RageSock']
      result = manager.fetch_scored_revisions(enrolled_usernames)
      
      expect(result.first[:wp10]).to be_nil
    end
  end
end
