# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/revision_score_manager"

describe RevisionScoreManager do
  let(:article) { create(:article, mw_page_id: 46721259) }
  let(:course) { create(:course, start: '2023-01-01', end: '2023-02-01') }
  let(:manager) { described_class.new(article, course) }

  describe '#fetch_scored_revisions' do
    let(:wiki_api_response) do
      {
        'query' => {
          'pages' => {
            '46721259' => {
              'revisions' => [
                { 'revid' => 1189_344_512, 'user' => 'RageSock',
                  'timestamp' => '2023-01-10T12:00:00Z', 'size' => 42_100 },
                { 'revid' => 1189_201_347, 'user' => 'WikiedStaff',
                  'timestamp' => '2023-01-09T08:30:00Z', 'size' => 41_800 }
              ]
            }
          }
        }
      }
    end

    let(:lift_wing_scores) do
      {
        '1189344512' => { 'wp10' => 0.5 }
      }
    end

    before do
      allow_any_instance_of(WikiApi).to receive(:query).and_return(wiki_api_response)
      allow_any_instance_of(LiftWingApi).to receive(:get_revision_data).and_return(lift_wing_scores)
    end

    it 'returns formatted data only for enrolled users' do
      enrolled_usernames = ['RageSock', 'MillerWon']
      result = manager.fetch_scored_revisions(enrolled_usernames)

      expect(result.length).to eq(1)
      expect(result.first[:rev_id]).to eq(1189_344_512)
      expect(result.first[:username]).to eq('RageSock')
      expect(result.first[:wp10]).to eq(0.5)
    end

    it 'returns an empty array if no revisions match enrolled users' do
      enrolled_usernames = ['MillerWon']
      result = manager.fetch_scored_revisions(enrolled_usernames)
      expect(result).to eq([])
    end

    it 'handles cases where LiftWing scores are missing' do
      allow_any_instance_of(LiftWingApi).to receive(:get_revision_data).and_return({})
      enrolled_usernames = ['RageSock']
      result = manager.fetch_scored_revisions(enrolled_usernames)

      expect(result.first[:wp10]).to be_nil
    end

    context 'when the API response spans multiple pages' do
      let(:first_page_response) do
        {
          'query' => {
            'pages' => {
              '46721259' => {
                'revisions' => [
                  { 'revid' => 1189_344_512, 'user' => 'RageSock',
                    'timestamp' => '2023-01-15T12:00:00Z', 'size' => 42_100 },
                  { 'revid' => 1189_344_345, 'user' => 'WikiEdStaff',
                    'timestamp' => '2023-02-15T12:00:00Z', 'size' => 42_400 }
                ]
              }
            }
          },
          'continue' => { 'rvcontinue' => '20230115120000|1189344512', 'continue' => '-||' }
        }
      end

      let(:second_page_response) do
        {
          'query' => {
            'pages' => {
              '46721259' => {
                'revisions' => [
                  { 'revid' => 1189_201_347, 'user' => 'RageSock',
                    'timestamp' => '2023-01-10T08:30:00Z', 'size' => 41_800 },
                  { 'revid' => 1189_201_346, 'user' => 'WikiEdStaff',
                    'timestamp' => '2023-04-10T08:30:00Z', 'size' => 41_800 }
                ]
              }
            }
          }
        }
      end

      let(:wiki_api) { instance_double(WikiApi) }

      before do
        allow(WikiApi).to receive(:new).and_return(wiki_api)
        allow(wiki_api).to receive(:query).and_return(first_page_response, second_page_response)
        allow_any_instance_of(LiftWingApi).to receive(:get_revision_data)
          .and_return('1189344512' => { 'wp10' => 0.62 }, '1189201347' => { 'wp10' => 0.58 })
      end

      it 'collects revisions across all pages until no continue token remains' do
        result = manager.fetch_scored_revisions(['RageSock'])

        expect(result.length).to eq(2)
        expect(result.map { |r| r[:rev_id] }).to contain_exactly(1189_344_512, 1189_201_347)
      end

      it 'makes one API call per page' do
        expect(wiki_api).to receive(:query).twice
        manager.fetch_scored_revisions(['RageSock'])
      end
    end
  end
end
