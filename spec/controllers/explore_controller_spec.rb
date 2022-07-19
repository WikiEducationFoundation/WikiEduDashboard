# frozen_string_literal: true

require 'rails_helper'

describe ExploreController, type: :request do
  let!(:campaign) do
    create(:campaign, title: 'My awesome campaign',
                      start: Date.civil(2016, 1, 10),
                      end: Date.civil(2050, 1, 10))
  end

  let(:admin) { create(:admin) }

  describe '#index' do
    it 'redirects to campaign overview if given a campaign URL param' do
      campaign = create(:campaign)
      get '/explore', params: { campaign: campaign.slug }
      expect(response.status).to eq(302)
      expect(response).to redirect_to(campaign_path(campaign.slug))
    end
  end
end
