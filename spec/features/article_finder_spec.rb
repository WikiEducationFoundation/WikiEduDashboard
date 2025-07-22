# frozen_string_literal: true

require 'rails_helper'

describe 'article finder', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin) }
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }

  before do
    login_as(admin)
    stub_wiki_validation
    course.wikis << wikidata
    stub_oauth_edit
  end

  it 'performs searches and returns results' do
    visit "/courses/#{course.slug}/article_finder"
    within '.article-finder-form' do
      fill_in 'article-searchbar', with: 'Selfie'
      click_button 'Search'
    end
    expect(page).to have_content 'Monkey selfie copyright dispute'
    expect(page).to have_content 'Add as available article'
  end

  it 'works for other tracked wikis besides the home wiki' do
    visit "/courses/#{course.slug}/article_finder"
    click_link 'Change'
    find('div.wiki-select').click
    within('.wiki-select') do
      find('input').send_keys('www.wikidata', :enter)
    end
    within '.article-finder-form' do
      fill_in 'article-searchbar', with: 'Selfie'
      click_button 'Search'
    end
    expect(page).to have_content 'Q12068677'
  end
end
