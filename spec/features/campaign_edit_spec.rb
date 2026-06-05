# frozen_string_literal: true

require 'rails_helper'

describe 'campaign edit page', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:campaign) { create(:campaign) }

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit "/campaigns/#{campaign.slug}/edit"
    expect(page).to have_content campaign.title
    expect(page).to be_axe_clean
  end
end
