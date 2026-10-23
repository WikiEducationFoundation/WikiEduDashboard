# frozen_string_literal: true

require 'rails_helper'

describe DetectorComparisonController, type: :request do
  include_context 'published detector comparison data'

  before { PublishDetectorComparison.new }

  context 'for a visitor who is not logged in' do
    it 'renders the page shell' do
      get '/detector_comparison'
      expect(response.body).to include('react_root')
    end

    it 'serves the page introduction and the size of each published dataset for the index' do
      get '/detector_comparison.json'
      expect(response.parsed_body['intro']).to include('preamble_html', 'views')
      expect(response.parsed_body['counts']).to eq('topics' => 4, 'known_human' => 1)
      expect(response.parsed_body['published_at']).to be_present
    end

    it 'serves the published 16-topic data' do
      get '/detector_comparison/topics.json'
      ids = response.parsed_body['units'].map { |unit| unit['id'] }
      expect(ids).to contain_exactly(generated.id, human.id, agpedia_article.id,
                                     article_after_term.id)
    end

    it 'serves the published known-human data' do
      get '/detector_comparison/known_human.json'
      expect(response.parsed_body['units'].map { |unit| unit['id'] }).to eq([human.id])
    end

    it 'sends the gzipped copy to a browser that takes gzip' do
      get '/detector_comparison/topics.json', headers: { 'Accept-Encoding' => 'gzip, br' }
      expect(response.headers['Content-Encoding']).to eq('gzip')
      expect(response.headers['Vary']).to include('Accept-Encoding')
      expect(response.headers['Content-Disposition']).to include('filename="topics.json"')
      units = JSON.parse(ActiveSupport::Gzip.decompress(response.body))['units']
      expect(units.size).to eq(4)
    end

    it 'answers a repeat request with not modified until the next publication' do
      get "/detector_comparison/units/#{generated.id}.json"
      etag = response.headers['ETag']
      get "/detector_comparison/units/#{generated.id}.json", headers: { 'If-None-Match' => etag }
      expect(response).to have_http_status(:not_modified)

      travel_to(1.minute.from_now) { PublishDetectorComparison.new }
      get "/detector_comparison/units/#{generated.id}.json", headers: { 'If-None-Match' => etag }
      expect(response).to have_http_status(:ok)
    end

    it 'serves the page shell for each dataset' do
      %w[/detector_comparison/topics /detector_comparison/known_human].each do |path|
        get path
        expect(response.body).to include('react_root')
      end
    end

    it 'serves a unit in full, and the page shell for its URL' do
      get "/detector_comparison/units/#{generated.id}.json"
      expect(response.parsed_body['text']).to eq(generated_text)
      get "/detector_comparison/units/#{generated.id}"
      expect(response.body).to include('react_root')
    end

    it 'serves the page shell for a topic' do
      get "/detector_comparison/topics/#{ERB::Util.url_encode("Marsy's Law")}"
      expect(response.body).to include('react_root')
    end

    it 'is not found for a unit the page does not list' do
      get "/detector_comparison/units/#{retired.id}.json"
      expect(response).to have_http_status(:not_found)
      get '/detector_comparison/units/..%2Fmanifest.json'
      expect(response).to have_http_status(:not_found)
    end

    it 'has no data before the first publication' do
      FileUtils.rm_rf(snapshot_root)
      get '/detector_comparison/topics.json'
      expect(response).to have_http_status(:not_found)
      get '/detector_comparison.json'
      expect(response.parsed_body).to include('counts' => nil)
    end

    it 'does not exist on the Programs & Events Dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get '/detector_comparison'
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'as a user who is not an admin' do
    before { login_as create(:user) }

    it 'serves the page and its data' do
      get '/detector_comparison'
      expect(response.body).to include('react_root')
      get '/detector_comparison/topics.json'
      expect(response.parsed_body['units'].size).to eq(4)
    end
  end
end
