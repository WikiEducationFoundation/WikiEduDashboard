# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/workers/report_csv_worker"

describe ReportCsvWorker, :report_csv_files do
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course) }

  before do
    campaign.courses << course
  end

  describe '.campaign_csv_name' do
    it 'builds standard campaign CSV filename without courses' do
      expected = "#{campaign.slug}-campaign_courses-#{Time.zone.today}.csv"
      expect(described_class.campaign_csv_name(campaign, 'campaign_courses')).to eq(expected)
    end

    it 'builds campaign CSV filename with courses segment when course is true' do
      expected = "#{campaign.slug}-campaign_students-with_courses-#{Time.zone.today}.csv"
      filename = described_class.campaign_csv_name(campaign, 'campaign_students', course: true)
      expect(filename).to eq(expected)
    end
  end

  describe '.campaign_zip_name' do
    it 'builds the campaign zip archive filename' do
      expected = "#{campaign.slug}-campaign-data-#{Time.zone.today}.zip"
      expect(described_class.campaign_zip_name(campaign)).to eq(expected)
    end
  end

  describe '#perform with campaign_all' do
    let(:zip_filename) { described_class.campaign_zip_name(campaign) }

    before do
      allow(CsvCleanupWorker).to receive(:perform_at)
    end

    it 'creates a zip containing all 5 CSV files' do
      expect(CsvCleanupWorker).to receive(:perform_at).with(anything, zip_filename)
      described_class.new.perform(campaign.id, zip_filename, 'campaign_all', nil)
      expect(ReportCsvStore.exists?(zip_filename)).to be(true)

      zip_data = ReportCsvStore.read(zip_filename)
      archive = Zip::File.open_buffer(zip_data)

      expect(archive.entries.map(&:name)).to match_array([
        'students.csv',
        'students-by-course.csv',
        'instructors-by-course.csv',
        'courses.csv',
        'pages-edited.csv'
      ])
    end

    it 'reuses existing CSV files from ReportCsvStore when already present' do
      courses_filename = described_class.campaign_csv_name(campaign, 'campaign_courses')
      ReportCsvStore.write(courses_filename, "cached,courses,data\n")

      expect_any_instance_of(CampaignCsvBuilder).not_to receive(:courses_to_csv)

      described_class.new.perform(campaign.id, zip_filename, 'campaign_all', nil)
      zip_data = ReportCsvStore.read(zip_filename)
      archive = Zip::File.open_buffer(zip_data)
      expect(archive.read('courses.csv')).to eq("cached,courses,data\n")
    end
  end
end
