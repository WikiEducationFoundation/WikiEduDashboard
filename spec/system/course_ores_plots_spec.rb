# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/histogram_plotter"

describe 'Course ORES plots', type: :system do
  describe '#course_plot' do
    let(:course) { create(:course) }
    let(:file_path) { 'assets/system/analytics/School—Title_(Term)-ores-0.png' }
    before do
      allow_any_instance_of(HistogramPlotter).to receive(:initialize_r)
      allow_any_instance_of(HistogramPlotter).to receive(:load_dataframe)
      allow_any_instance_of(HistogramPlotter).to receive(:major_edits_plot)
        .and_return(file_path)
    end

    it 'returns a file path' do
      visit "/courses/#{course.slug}/ores_plot.json"
      expect(page).to have_text(file_path)
    end
  end
end
