# frozen_string_literal: true

require 'csv'
require "#{Rails.root}/lib/analytics/course_csv_builder"

class CampaignCsvBuilder
  def initialize(campaign)
    @campaign = campaign
  end

  def courses_to_csv
    csv_data = [CourseCsvBuilder::CSV_HEADERS]
    @campaign.courses.each do |course|
      csv_data << CourseCsvBuilder.new(course).row
    end

    CSV.generate { |csv| csv_data.uniq.each { |line| csv << line } }
  end
end
