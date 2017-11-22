# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/histogram_plotter"

describe 'ORES plots', type: :feature do
  before(:each) do
    allow(HistogramPlotter).to receive(:plot).and_return(file_path)
  end

  describe 'for a single course' do
    let(:course) { create(:course) }
    let(:file_path) { 'assets/system/analytics/School—Title_(Term)-ores-0.png' }

    it 'returns a file path' do
      visit "/courses/#{course.slug}/ores_plot.json"
      expect(page).to have_text(file_path)
    end
  end

  describe 'for a campaign' do
    let(:campaign) { create(:campaign) }
    let(:file_path) { 'assets/system/analytics/campaign_slug-ores-0.png' }

    it 'renders without error' do
      visit "/campaigns/#{campaign.slug}/ores_plot"
      expect(page).to have_text('ORES')
    end
  end
end
