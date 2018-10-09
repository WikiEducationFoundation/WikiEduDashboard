# frozen_string_literal: true

require 'rails_helper'

describe 'article finder', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
    stub_oauth_edit
  end

  it 'performs searches and returns results' do
    visit "/courses/#{course.slug}/article_finder"
    within '.article-finder-form' do
      fill_in 'category', with: 'Selfie'
      click_button 'Submit'
    end
    expect(page).to have_content 'Monkey selfie copyright dispute'
    expect(page).to have_content 'Add as available article'
  end
end
