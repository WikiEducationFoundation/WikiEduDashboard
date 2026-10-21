# frozen_string_literal: true

require 'rails_helper'

describe LookupsController, type: :request do
  describe '#campaign' do
    before do
      create(:campaign, title: 'Lookup Campaign', slug: 'lookup_campaign')
    end

    it 'returns all campaigns with id, title, and slug' do
      get '/lookups/campaign.json'
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['campaigns'].length).to eq(Campaign.count)
      expect(body['campaigns'].first).to include('id', 'title', 'slug')
      expect(body['campaigns'].first).not_to include('course_count')
      expect(body['total_pages']).to be_nil
    end
  end
end
