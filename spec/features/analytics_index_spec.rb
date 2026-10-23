# frozen_string_literal: true

require 'rails_helper'

describe 'analytics index page', type: :feature, js: true do
  let(:admin) { create(:admin) }

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit '/analytics'
    expect(page).to have_content 'Analytics Tools'
    expect(page).to be_axe_clean
  end

  it 'lists campaigns alphabetically in the campaign menus' do
    create(:campaign, title: 'Zebra Campaign', slug: 'zebra_campaign')
    create(:campaign, title: 'Aardvark Campaign', slug: 'aardvark_campaign')
    visit '/analytics'
    %w[campaign_1_id campaign_2_id mentor_requests_campaign_id
       mentor_volunteers_campaign_id].each do |select_id|
      titles = find("##{select_id}").all('option').map(&:text)
      expect(titles.index('Aardvark Campaign')).to be < titles.index('Zebra Campaign')
    end
  end
end
