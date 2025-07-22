# frozen_string_literal: true

require 'rails_helper'

describe 'course update statistics', type: :feature, js: true do
  let(:course) { create(:course) }

  before do
    course.campaigns << Campaign.first
    allow(Features).to receive(:wiki_ed?).and_return(false)
  end

  it 'shows links for downloading data' do
    visit "/courses/#{course.slug}"
    click_button 'Download stats'
    expect(page).to have_content('Overview data')
    expect(page).to have_content('Articles data')
  end
end
