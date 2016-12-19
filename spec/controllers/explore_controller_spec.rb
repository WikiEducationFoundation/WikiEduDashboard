# frozen_string_literal: true
require 'rails_helper'

describe ExploreController do
  let(:campaign) { create(:campaign) }

  describe '#index' do
    it 'should redirect to campaign overview if given a campaign URL param' do
      get :index, params: { campaign: campaign.slug }
      expect(response.status).to eq(302)
      expect(response).to redirect_to(campaign_path(campaign.slug))
    end
  end
end
