# frozen_string_literal: true

require 'rails_helper'

describe 'Detailed course overview stats', type: :feature, js: true do
  let(:course) { create(:course, start: '2022-01-01', end: '2023-01-01') }
  before do
    create(:course_stats, course: course,
      stats_hash: {
        'www.wikidata.org': {
          'claims created': 35,
          'other updates': 2,
          'unknown': 6
        },
        'en.wikibooks.org-namespace-102': {
          'new_count': 5,
          'edited_count': 72
        },
        'en.wikipedia.org-namespace-0': {
          'new_count': 16,
          'edited_count': 103
        }
      }
    )
    visit "/courses/#{course.slug}"
  end

  it 'shows all the course_stat objects in a tabbed UI layout' do
    # Tabs corresponding to all the stats are rendered
    expect(page.find('#tab-0')).to have_content('www.wikidata.org')
    expect(page.find('#tab-1')).to have_content('en.wikibooks.org - Cookbook')
    expect(page.find('#tab-2')).to have_content('en.wikipedia.org - Mainspace')

    # Default tab's content matches first course_stat object's stats
    expect(page.find('.tab.active')).to have_content('www.wikidata.org')
    expect(page.find('.content-container .title')).to have_content('www.wikidata.org')
    expect(page.find('.content-container')).to have_content("Claims\n35")

    # Clicking other tabs renders the respective stats data
    page.find('.tab', text: 'en.wikibooks.org - Cookbook').click
    expect(page.find('.tab.active')).to have_content('en.wikibooks.org - Cookbook')
    expect(page.find('.content-container .title')).not_to have_content('www.wikidata.org')
    expect(page.find('.content-container .title')).to have_content('en.wikibooks.org - Cookbook')
    expect(page.find('.content-container')).to have_content("72\nArticles Edited")

    page.find('.tab', text: 'en.wikipedia.org - Mainspace').click
    expect(page.find('.tab.active')).to have_content('en.wikipedia.org - Mainspace')
    expect(page.find('.content-container .title')).not_to have_content('en.wikibooks.org - Cookbook')
    expect(page.find('.content-container .title')).to have_content('en.wikipedia.org - Mainspace')
    expect(page.find('.content-container')).to have_content("16\nArticles Created")
  end
end
