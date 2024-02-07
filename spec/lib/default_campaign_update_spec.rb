# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/deafult_campaign_update.rb"

describe DefaultCampaignUpdate do 
  before do
    Setting.create(key: 'default_campaign',
                   value: { :slug => 'default_campaign' })
  end

  describe 'when fall starts' do
    before do
      travel_to Date.new(2024, 9, 21)
    end

    context 'when current term exists as campaign' do
      it 'sets it as default campaign' do
        create(:campaign, id: 1, slug: 'fall_2024')
        expect(CampaignsPresenter.default_campaign_setting.value).to eq({:slug=>"default_campaign"})
        described_class.new
        expect(CampaignsPresenter.default_campaign_setting.value).to eq({:slug=>"fall_2024"})
      end
    end

    context 'when current term does not as campaign' do
      it 'default campaign keeps being the same' do
        expect(CampaignsPresenter.default_campaign_setting.value).to eq({:slug=>"default_campaign"})
        described_class.new
        expect(CampaignsPresenter.default_campaign_setting.value).to eq({:slug=>"default_campaign"})
      end
    end
  end

  describe 'when spring starts' do
    before do
      travel_to Date.new(2024, 3, 21)
    end

    context 'when current term exists as campaign' do
      it 'sets it as default campaign' do
        create(:campaign, id: 1, slug: 'spring_2024')
        expect(CampaignsPresenter.default_campaign_setting.value).to eq({:slug=>"default_campaign"})
        described_class.new
        expect(CampaignsPresenter.default_campaign_setting.value).to eq({:slug=>"spring_2024"})
      end
    end

    context 'when current term does not as campaign' do
      it 'default campaign keeps being the same' do
        expect(CampaignsPresenter.default_campaign_setting.value).to eq({:slug=>"default_campaign"})
        described_class.new
        expect(CampaignsPresenter.default_campaign_setting.value).to eq({:slug=>"default_campaign"})
      end
    end
  end
end
