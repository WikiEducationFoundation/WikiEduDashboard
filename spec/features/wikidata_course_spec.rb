# frozen_string_literal: true

require 'rails_helper'

describe 'A Wikidata course', type: :feature, js: true do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:course) { create(:course, home_wiki: wikidata, start: '2017-01-01', end: '2020-01-01') }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:article) { create(:article, title: 'Q42', wiki: wikidata) }

  before do
    stub_wiki_validation
    course.campaigns << Campaign.first
    create(:courses_user, course: course, user: user)
    create(:revision, article: article, user: user, date: '2019-01-01')
    create(:articles_course, course: course, article: article, user_ids: [user.id])
    create(:course_stats,
           stats_hash: { 'www.wikidata.org' => {
             'claims created' => 12, 'other updates' => 1, 'unknown' => 1
           } },
           course: course)
  end

  it 'shows Wikidata stats on the Home tab' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content('www.wikidata.org')
    expect(page).to have_content('Claims')
  end

  it 'has an Items tab instead of Articles tab' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'Items'
    expect(page).not_to have_content 'Articles'
  end

  it 'loads the labels for Wikidata Q items' do
    visit "/courses/#{course.slug}/articles"
    expect(page).to have_content 'Douglas Adams'
  end

  it 'shows wikidata stats on the Campaign page' do
    visit "/campaigns/#{Campaign.first.slug}/overview"
    expect(page).to have_content('Wikidata stats')
  end
end
