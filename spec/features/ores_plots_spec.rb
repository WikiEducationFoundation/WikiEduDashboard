# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/analytics/histogram_plotter')

describe 'ORES plots', type: :feature do
  describe 'for a single course' do
    let(:course) { create(:course, article_count: 1) }

    it 'returns a json array' do
      visit "/courses/#{escaped_slug course.slug}/ores_plot.json"
      expect(JSON.parse(page.body)).to eq('ores_plot' => [])
    end

    it 'rerenders via the refresh link', js: true do
      visit "/courses/#{escaped_slug course.slug}/articles/edited"
      click_button 'Change in Structural Completeness'
      click_link 'Refresh Cached Data'
      expect(page).to have_text('This graph visualizes')
    end
  end

  describe 'for a campaign', js: true do
    let(:campaign) { create(:campaign) }

    it 'renders without error' do
      visit "/campaigns/#{campaign.slug}/ores_plot"
      click_button 'Change in Structural Completeness'
      expect(page).to have_text('This graph visualizes')
    end
  end
end
