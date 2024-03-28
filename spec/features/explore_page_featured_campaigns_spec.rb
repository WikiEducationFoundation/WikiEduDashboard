# frozen_string_literal: true

require 'rails_helper'

describe 'featured campaigns explore page', type: :feature, js: true do
  let!(:campaign) { Campaign.default_campaign }
  let!(:campaign1) { create(:campaign, title: 'Test Campaign1', slug: 'test_campaign1') }
  let!(:campaign2) { create(:campaign, title: 'Test Campaign2', slug: 'test_campaign2') }
  let!(:campaign3) { create(:campaign, title: 'Test Campaign3', slug: 'test_campaign3') }
  let(:setting) { Setting.find_or_create_by(key: 'featured_campaigns') }
  let(:user) { create(:user) }

  def add_featured_campaigns(*campaigns)
    setting.value['campaign_slugs'] ||= []
    campaigns.each { |campaign| setting.value['campaign_slugs'] << campaign.slug }
    setting.save
  end

  describe 'featured campaigns are NOT listed' do
    before do
      login_as(user)
      visit '/explore'
    end

    it 'visit explore page' do # all campaigns must be present
      [campaign1, campaign2, campaign3, campaign].each do |campaign|
        expect(page).to have_content(campaign.title)
      end
    end
  end

  describe 'featured campaigns are listed' do
    before do
      login_as(user)
      visit '/explore'
      # only campagin1, campaign2, campaign3 are featured campaigns
      add_featured_campaigns(campaign1, campaign2, campaign3)
    end

    it 'visit explore page' do # only featured campaigns must be present
      [campaign1, campaign2, campaign3].each do |campaign|
        expect(page).to have_content(campaign.title)
      end
      expect(page).not_to have_content(campaign.title)
    end
  end
end
