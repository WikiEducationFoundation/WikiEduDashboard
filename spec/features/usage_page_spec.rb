require 'rails_helper'

describe 'usage page', type: :feature, js: true, js_error_expected: true do
  let(:en_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:fr_wiki) { Wiki.get_or_create(language: 'fr', project: 'wikipedia') }

  before do
    Course.create!(
      title: 'English Wiki Course',
      school: 'School',
      term: 'Term',
      slug: 'School/English_Wiki_Course',
      start: 1.month.ago,
      end: 1.month.from_now,
      home_wiki: en_wiki,
      passcode: 'pizza'
    )

    Course.create!(
      title: 'French Wiki Course',
      school: 'School',
      term: 'Term',
      slug: 'School/French_Wiki_Course',
      start: 1.month.ago,
      end: 1.month.from_now,
      home_wiki: fr_wiki,
      passcode: 'pizza'
    )
  end

  it 'shows usage data and wiki list table' do
    visit '/usage'
    expect(page).to have_text('Usage Stats')

    # Wiki list table should be visible with search and tabs
    expect(page).to have_css('.wiki-search')
    expect(page).to have_css('.wiki-tabs')
    expect(page).to have_css('.wiki-table')

    # Should show wiki data in the table
    expect(page).to have_text('en.wikipedia.org')
    expect(page).to have_text('fr.wikipedia.org')

    # Switch to Top 10 tab
    find('.wiki-tab', text: 'Top 10').click
    expect(page).to have_css('.wiki-table')

    # Switch to By project tab
    find('.wiki-tab', text: 'By project').click
    expect(page).to have_css('.wiki-group')

    # Switch to By language tab
    find('.wiki-tab', text: 'By language').click
    expect(page).to have_css('.wiki-group')

    # Search functionality
    find('.wiki-tab', text: 'All wikis').click
    fill_in 'wiki-search', with: 'en'
    expect(page).to have_text('en.wikipedia.org')
  end
end