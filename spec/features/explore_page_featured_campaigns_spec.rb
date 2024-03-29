# frozen_string_literal: true

require 'rails_helper'

describe 'explore page', type: :feature, js: true do
  let!(:campaign_1) do
    create(:campaign, title: 'Test Campaign_1', slug: 'test_campaign_1',
                      start: Date.civil(2016, 1, 10), end: Date.civil(2016, 2, 10),
                      created_at: Date.civil(2022, 1, 1))
  end
  let!(:campaign_2) do
    create(:campaign, title: 'Test Campaign 2', slug: 'test_campaign_2',
                      start: Date.civil(2017, 3, 28), end: Date.civil(2017, 4, 28),
                      created_at: Date.civil(2022, 1, 2))
  end
  let!(:campaign_3) do
    create(:campaign, title: 'Test Campaign 3', slug: 'test_campaign_3',
                      start: Date.civil(2018, 3, 29), end: Date.civil(2018, 4, 1),
                      created_at: Date.civil(2022, 1, 3))
  end
  let!(:campaign_4) do
    create(:campaign, title: 'Test Campaign 4', slug: 'test_campaign_4',
                      start: Date.civil(2019, 4, 1), end: Date.civil(2019, 4, 2),
                      created_at: Date.civil(2022, 1, 4))
  end
  let!(:campaign_5) do
    create(:campaign, title: 'Test Campaign 5', slug: 'test_campaign_5',
                      start: Date.civil(2020, 4, 2), end: Date.civil(2020, 4, 3),
                      created_at: Date.civil(2022, 1, 5))
  end
  let!(:campaign_6) do
    create(:campaign, title: 'Test Campaign 6', slug: 'test_campaign_6',
                      start: Date.civil(2021, 4, 3), end: Date.civil(2021, 4, 4),
                      created_at: Date.civil(2022, 1, 6))
  end
  let!(:campaign_7) do
    create(:campaign, title: 'Test Campaign 7', slug: 'test_campaign_7',
                      start: Date.civil(2022, 4, 4), end: Date.civil(2022, 4, 5),
                      created_at: Date.civil(2022, 1, 7))
  end
  let!(:campaign_8) do
    create(:campaign, title: 'Test Campaign 8', slug: 'test_campaign_8',
                      start: Date.civil(2016, 4, 5), end: Date.civil(2016, 4, 6),
                      created_at: Date.civil(2022, 1, 8))
  end
  let!(:campaign_9) do
    create(:campaign, title: 'Test Campaign 9', slug: 'test_campaign_9',
                      start: Date.civil(2017, 4, 6), end: Date.civil(2017, 4, 7),
                      created_at: Date.civil(2022, 1, 9))
  end
  let!(:campaign_10) do
    create(:campaign, title: 'Test Campaign 10', slug: 'test_campaign_10',
                      start: Date.civil(2018, 4, 7), end: Date.civil(2018, 4, 8),
                      created_at: Date.civil(2022, 1, 10))
  end
  let!(:campaign_11) do
    create(:campaign, title: 'Test Campaign 11', slug: 'test_campaign_11',
                      start: Date.civil(2019, 4, 8), end: Date.civil(2019, 4, 9),
                      created_at: Date.civil(2022, 1, 11))
  end
  let!(:campaign_12) do
    create(:campaign, title: 'Test Campaign 12', slug: 'test_campaign_12',
                      start: Date.civil(2018, 4, 3), end: Date.civil(2019, 8, 9),
                      created_at: Date.civil(2022, 1, 12))
  end
  let(:admin) { create(:admin) }

  def add_featured_campaigns(campaign_1, campaign_2)
    click_button 'Update Featured Campaigns'
    fill_in 'add_campaign_slug', with: campaign_1.slug
    click_button 'Add Campaign'
    fill_in 'add_campaign_slug', with: campaign_2.slug
    click_button 'Add Campaign'

    expect(page).to have_content(campaign_1.slug)
    expect(page).to have_content(campaign_2.slug)
  end

  describe 'featured campaigns are NOT listed' do
    before do
      login_as(admin)
      visit '/explore'
    end

    # only 10 campaigns must be present
    it 'visit explore page' do
      expect(page).to have_content('Newest Campaigns')
      within '#campaigns_list tbody' do
        tr_count = all('tr').count
        expect(tr_count).to eq(10)
      end
      # latest 10 campaigns created are from campaign_3 to campaign_12
      expect(page).not_to have_content(campaign_1.title)
      expect(page).not_to have_content(campaign_2.title)
    end
  end

  describe 'featured campaigns are listed' do
    before do
      login_as(admin)
      visit '/settings'
      add_featured_campaigns(campaign_1, campaign_2)
    end

    # only 2 campaigns must be present
    it 'visit explore page' do
      visit '/explore'
      expect(page).to have_content('Featured Campaigns')
      within '#campaigns_list tbody' do
        tr_count = all('tr').count
        expect(tr_count).to eq(2)
      end
      expect(page).to have_content(campaign_1.title)
      expect(page).to have_content(campaign_2.title)
    end
  end
end
