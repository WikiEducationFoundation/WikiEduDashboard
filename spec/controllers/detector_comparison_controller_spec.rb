# frozen_string_literal: true

require 'rails_helper'

describe DetectorComparisonController, type: :request do
  include_context 'detector comparison data'

  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  context 'as an admin' do
    before { login_as admin }

    it 'renders the page shell' do
      get '/detector_comparison'
      expect(response.body).to include('react_root')
    end

    it 'serves the comparison data' do
      get '/detector_comparison.json'
      ids = response.parsed_body['units'].map { |unit| unit['id'] }
      expect(ids).to contain_exactly(generated.id, human.id)
    end

    it 'serves a unit in full, and the page shell for its URL' do
      get "/detector_comparison/units/#{generated.id}.json"
      expect(response.parsed_body['text']).to eq(generated_text)
      get "/detector_comparison/units/#{generated.id}"
      expect(response.body).to include('react_root')
    end

    it 'is not found for a unit the page does not list' do
      get "/detector_comparison/units/#{retired.id}.json"
      expect(response).to have_http_status(:not_found)
    end

    it 'does not exist on the Programs & Events Dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get '/detector_comparison'
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'as a non-admin' do
    before { login_as user }

    it 'is not authorized' do
      get '/detector_comparison.json'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
