# frozen_string_literal: true

require 'rails_helper'

describe 'explore page', type: :feature, js: true do
  let!(:campaign1) do
    create(:campaign, title: 'Test Campaign1', slug: 'test_campaign1',
                      start: Date.civil(2016, 1, 10), end: Date.civil(2016, 2, 10))
  end
  let!(:campaign2) do
    create(:campaign, title: 'Test Campaign2', slug: 'test_campaign2',
                      start: Date.civil(2017, 3, 28), end: Date.civil(2017, 4, 28))
  end
  let!(:campaign3) do
    create(:campaign, title: 'Test Campaign3', slug: 'test_campaign3',
                      start: Date.civil(2018, 3, 29), end: Date.civil(2018, 4, 1))
  end
  let!(:campaign4) do
    create(:campaign, title: 'Test Campaign4', slug: 'test_campaign4',
                      start: Date.civil(2019, 4, 1), end: Date.civil(2019, 4, 2))
  end
  let!(:campaign5) do
    create(:campaign, title: 'Test Campaign5', slug: 'test_campaign5',
                      start: Date.civil(2020, 4, 2), end: Date.civil(2020, 4, 3))
  end
  let!(:campaign6) do
    create(:campaign, title: 'Test Campaign6', slug: 'test_campaign6',
                      start: Date.civil(2021, 4, 3), end: Date.civil(2021, 4, 4))
  end
  let!(:campaign7) do
    create(:campaign, title: 'Test Campaign7', slug: 'test_campaign7',
                      start: Date.civil(2022, 4, 4), end: Date.civil(2022, 4, 5))
  end
  let!(:campaign8) do
    create(:campaign, title: 'Test Campaign8', slug: 'test_campaign8',
                      start: Date.civil(2016, 4, 5), end: Date.civil(2016, 4, 6))
  end
  let!(:campaign9) do
    create(:campaign, title: 'Test Campaign9', slug: 'test_campaign9',
                      start: Date.civil(2017, 4, 6), end: Date.civil(2017, 4, 7))
  end
  let!(:campaign20) do
    create(:campaign, title: 'Test campaign20', slug: 'test_campaign20',
                      start: Date.civil(2018, 4, 7), end: Date.civil(2018, 4, 8))
  end
  let!(:campaign21) do
    create(:campaign, title: 'Test campaign21', slug: 'test_campaign21',
                      start: Date.civil(2019, 4, 8), end: Date.civil(2019, 4, 9))
  end
  let!(:campaign22) do
    create(:campaign, title: 'Test campaign22', slug: 'test_campaign22',
                      start: Date.civil(2018, 4, 3), end: Date.civil(2019, 8, 9))
  end
  let(:admin) { create(:admin) }

  def add_featured_campaigns(campaign1, campaign2)
    click_button 'Update Featured Campaigns'
    fill_in 'add_campaign_slug', with: campaign1.slug
    click_button 'Add Campaign'
    fill_in 'add_campaign_slug', with: campaign2.slug
    click_button 'Add Campaign'

    expect(page).to have_content(campaign1.slug)
    expect(page).to have_content(campaign2.slug)
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
      # latest 10 campaigns created are from campaign3 to campaign22
      expect(page).not_to have_content(campaign1.title)
      expect(page).not_to have_content(campaign2.title)
    end
  end

  describe 'featured campaigns are listed' do
    before do
      login_as(admin)
      visit '/settings'
      add_featured_campaigns(campaign1, campaign2)
    end

    # only 2 campaigns must be present
    it 'visit explore page' do
      visit '/explore'
      expect(page).to have_content('Featured Campaigns')
      within '#campaigns_list tbody' do
        tr_count = all('tr').count
        expect(tr_count).to eq(2)
      end
      expect(page).to have_content(campaign1.title)
      expect(page).to have_content(campaign2.title)
    end
  end
end
