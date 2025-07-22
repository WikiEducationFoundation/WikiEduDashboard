# frozen_string_literal: true

require 'csv'

class CourseUploadsCsvBuilder
  def initialize(course)
    @course = course
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    @course.uploads.includes(:user).each do |upload|
      csv_data << row(upload)
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  private

  CSV_HEADERS = %w[
    filename
    commons_page
    timestamp
    username
    usage_count
    deleted
  ].freeze
  def row(upload)
    row = [upload.file_name]
    row << upload.url
    row << upload.uploaded_at
    row << upload.user.username
    row << upload.usage_count
    row << upload.deleted
  end
end
