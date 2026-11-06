# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/histogram_plotter.rb"

describe HistogramPlotter do
  let(:course) do
    create(:course, slug: "Sage's/te,_st_(slug)", id: 1, start: 1.year.ago, end: 1.day.from_now)
  end
  let(:opts) { { existing_only: true, minimum_improvement: 1 } }
  let(:article) { create(:article) }

  before do
    FileUtils.rm_rf "#{Rails.root}/tmp/ores_plot"
  end

  after do
    FileUtils.rm_rf "#{Rails.root}/tmp/ores_plot"
  end

  context 'when files from earlier days exist' do
    let(:dir) { "#{Rails.root}/tmp/ores_plot" }
    let(:old_file) { "#{dir}/Sage-s—te,_st_(slug)-2020-01-01.csv" }
    let(:other_course_file) { "#{dir}/Sage-s—te,_st_(slug)_extra-2020-01-01.csv" }

    before do
      FileUtils.mkdir_p dir
      FileUtils.touch [old_file, other_course_file]
    end

    it 'removes the course\'s earlier files and leaves other courses\' files' do
      csv = described_class.csv(course:)
      expect(File.exist?(csv)).to be true
      expect(File.exist?(old_file)).to be false
      expect(File.exist?(other_course_file)).to be true
    end
  end

  context 'when there is no article data' do
    it 'returns an empty CSV' do
      csv = described_class.csv(course:)
      expect(File.readlines(csv).count).to eq(1)
    end
  end

  context 'when there is article data' do
    before do
      course.articles << article
    end

    it 'returns a deletable CSV with article data for a course' do
      csv = described_class.csv(course:)
      expect(File.readlines(csv).count).to eq(2)

      expect(File.exist?(csv)).to eq(true)
      described_class.delete_csv(course:)
      expect(File.exist?(csv)).to eq(false)
    end

    it 'returns a deletable CSV with article data for a campaign' do
      course.campaigns << Campaign.first
      csv = described_class.csv(campaign: Campaign.first)
      expect(File.readlines(csv).count).to eq(2)

      expect(File.exist?(csv)).to eq(true)
      described_class.delete_csv(campaign: Campaign.first)
      expect(File.exist?(csv)).to eq(false)
    end

    it 'leaves private courses out of a campaign CSV' do
      course.update(private: true)
      course.campaigns << Campaign.first
      csv = described_class.csv(campaign: Campaign.first)
      expect(File.readlines(csv).count).to eq(1)
    end

    it 'keeps the CSV out of the public directory' do
      expect(described_class.csv(course:)).not_to start_with('public/')
    end
  end
end
