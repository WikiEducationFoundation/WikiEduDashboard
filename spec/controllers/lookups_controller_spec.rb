# frozen_string_literal: true

require 'rails_helper'

describe LookupsController, type: :request do
  describe '#campaign' do
    before do
      30.times do |i|
        create(:campaign, title: "Lookup Campaign #{i + 1}", slug: "lookup_campaign_#{i + 1}")
      end
    end

    it 'returns all campaigns when page parameter is omitted' do
      get '/lookups/campaign.json'
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['campaigns'].length).to eq(Campaign.count)
      expect(body['total_pages']).to be_nil
    end

    it 'paginates with limit 25 when page parameter is provided' do
      get '/lookups/campaign.json', params: { page: 1 }
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['campaigns'].length).to eq(25)
      expect(body['total_pages']).to eq(2)
      expect(body['current_page']).to eq(1)
    end

    it 'returns the remaining campaigns on the second page' do
      total = Campaign.count
      get '/lookups/campaign.json', params: { page: 2 }
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['campaigns'].length).to eq(total - 25)
      expect(body['current_page']).to eq(2)
    end

    it 'filters campaigns by search query' do
      get '/lookups/campaign.json', params: { search: 'Lookup Campaign 10', page: 1 }
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['campaigns'].length).to eq(1)
      expect(body['campaigns'].first['title']).to eq('Lookup Campaign 10')
    end
  end
end
