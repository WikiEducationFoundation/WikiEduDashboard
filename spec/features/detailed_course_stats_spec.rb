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

  it 'shows tabs for all the course stats objects' do
    expect(page.find('#tab-0')).to have_content('www.wikidata.org')
    expect(page.find('#tab-1')).to have_content('en.wikibooks.org - Cookbook')
    expect(page.find('#tab-2')).to have_content('en.wikipedia.org - Mainspace')
  end

  it 'shows cookbook stats on clicking the \'en.wikibooks.org - Cookbook\' tab' do
    page.find('#tab-1').click
    expect(page).to have_content('en.wikibooks.org - Cookbook')
    expect(page).to have_content('Articles Edited')
  end

  it 'shows wikidata overview stats on clicking the \'www.wikidata.org\' tab' do
    page.find('#tab-0').click
    expect(page).to have_content('www.wikidata.org')
    expect(page).to have_content('Claims')
  end
end
