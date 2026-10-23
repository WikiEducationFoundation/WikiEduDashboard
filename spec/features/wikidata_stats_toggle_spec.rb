# frozen_string_literal: true

require 'rails_helper'

describe 'Wikidata stats toggle', type: :feature, js: true do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:campaign) { create(:campaign, title: 'Wikidata Review Campaign') }
  # Production-shaped sparse hash: every key present, most zero
  let(:sparse_stats) do
    keys = ['total revisions', 'merged to', 'merged from', 'interwiki links added',
            'items created', 'items cleared', 'claims created', 'claims changed',
            'claims removed', 'labels added', 'labels changed', 'labels removed',
            'descriptions added', 'descriptions changed', 'descriptions removed',
            'aliases added', 'aliases changed', 'aliases removed', 'qualifiers added',
            'references added', 'redirects created', 'reverts performed',
            'restorations performed', 'other updates', 'lexeme items created', 'unknown']
    keys.to_h { |k| [k, 0] }.merge('total revisions' => 11, 'claims created' => 3,
                                   'labels added' => 4, 'reverts performed' => 2)
  end

  before { stub_wiki_validation }

  def setup_course(home_wiki)
    course = create(:course, home_wiki:, start: '2017-01-01', end: '2020-01-01',
                             slug: "School/Course_#{home_wiki.project}_(term)")
    course.wikis << wikidata unless course.wikis.include?(wikidata)
    course.campaigns << campaign
    create(:course_stats, course:, stats_hash: { 'www.wikidata.org' => sparse_stats })
    course
  end

  context 'course whose home wiki is Wikidata' do
    it 'starts expanded' do
      course = setup_course(wikidata)
      visit "/courses/#{course.slug}"
      expect(page).to have_css('.wikidata-stats-toggle')
      expect(page).to have_css('.wikidata-stats-toggle[aria-expanded="true"]')
      expect(page).to have_content('Claims')
    end
  end

  context 'course whose home wiki is not Wikidata' do
    let!(:course) { setup_course(enwiki) }

    it 'starts collapsed, and the toggle expands and collapses it' do
      visit "/courses/#{course.slug}"
      expect(page).to have_css('.wikidata-stats-toggle[aria-expanded="false"]')
      expect(page).not_to have_css('#wikidata-stats-content')

      find('.wikidata-stats-toggle').click
      expect(page).to have_css('.wikidata-stats-toggle[aria-expanded="true"]')
      expect(page).to have_css('#wikidata-stats-content')

      find('.wikidata-stats-toggle').click
      expect(page).not_to have_css('#wikidata-stats-content')
    end

    it 'toggles with the keyboard' do
      visit "/courses/#{course.slug}"
      find('.wikidata-stats-toggle').send_keys(:enter)
      expect(page).to have_css('#wikidata-stats-content')
      find('.wikidata-stats-toggle').send_keys(:space)
      expect(page).not_to have_css('#wikidata-stats-content')
    end

    it 'hides zero-valued stats and empty categories' do
      visit "/courses/#{course.slug}"
      find('.wikidata-stats-toggle').click
      within('#wikidata-stats-content') do
        labels = all('.stats-label').map(&:text)
        expect(labels).to eq(%w[General Claims Labels Other])
        expect(page).to have_css('#total-revisions')
        expect(page).to have_css('#claims-created')
        expect(page).not_to have_css('#claims-changed')
        expect(page).not_to have_css('#merged')
        expect(page).to have_css('#reverts-performed')
        expect(page).not_to have_css('#qualifiers-added')
      end
    end
  end

  context 'campaign overview' do
    it 'starts expanded and keeps a heading for the card' do
      setup_course(enwiki)
      visit "/campaigns/#{campaign.slug}/overview"
      expect(page).to have_css('.wikidata-stats-toggle[aria-expanded="true"]')
      within('.wikidata-stats-container') do
        expect(page).to have_css('h2', text: 'Wikidata stats')
      end
    end

    it 'does not render an empty card when every stat is zero' do
      course = setup_course(enwiki)
      all_zero = sparse_stats.transform_values { 0 }
      course.course_stat.update(stats_hash: { 'www.wikidata.org' => all_zero })
      visit "/campaigns/#{campaign.slug}/overview"
      expect(page).to have_css('#courses-count')
      expect(page).not_to have_css('.wikidata-stats-container')
    end
  end
end
