require 'rails_helper'

describe 'usage page', type: :feature, js: true, js_error_expected: true do
  let(:en_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:fr_wiki) { Wiki.get_or_create(language: 'fr', project: 'wikipedia') }

  before do
    # Create some courses to have data on the page
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

  it 'shows usage data and toggles wiki lists' do
    visit '/usage'
    expect(page).to have_text('Usage Stats')

    # Initially, "All Wikis" should be visible
    expect(page).to have_css('#wiki-list-all', visible: true)
    expect(page).to have_css('#wiki-list-top10', visible: false)

    # Change to "Top 10"
    find('#wiki-view-dropdown').select('Top 10 Most Active Wikis')
    expect(page).to have_css('#wiki-list-top10', visible: true)
    expect(page).to have_css('#wiki-list-all', visible: false)

    # Change to "Project Type"
    find('#wiki-view-dropdown').select('Sort by Project Type')
    expect(page).to have_css('#wiki-list-project', visible: true)
    expect(page).to have_css('#wiki-list-top10', visible: false)

    # Change to "Language"
    find('#wiki-view-dropdown').select('Sort by Language')
    expect(page).to have_css('#wiki-list-language', visible: true)
    expect(page).to have_css('#wiki-list-project', visible: false)

    # Save a screenshot so the user can see the result
    page.save_screenshot('tmp/screenshots/usage_page_test_result.png')
    puts "\nScreenshot saved to: tmp/screenshots/usage_page_test_result.png"
  end
end
