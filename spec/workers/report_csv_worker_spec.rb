# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/workers/report_csv_worker"

describe ReportCsvWorker, :report_csv_files do
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course) }

  before do
    campaign.courses << course
  end

  describe '#to_campaign_zip' do
    it 'creates a zip containing all 5 CSV files' do
      zip_data = described_class.new.to_campaign_zip(campaign.id)
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
      worker = described_class.new
      courses_filename = "#{campaign.slug}-campaign_courses-#{Time.zone.today}.csv"
      ReportCsvStore.write(courses_filename, "cached,courses,data\n")

      expect_any_instance_of(CampaignCsvBuilder).not_to receive(:courses_to_csv)

      zip_data = worker.to_campaign_zip(campaign.id)
      archive = Zip::File.open_buffer(zip_data)
      expect(archive.read('courses.csv')).to eq("cached,courses,data\n")
    end
  end
end
