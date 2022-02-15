# frozen_string_literal: true

require 'csv'
require_dependency "#{Rails.root}/lib/wikidata_summary_parser"

class CourseWikidataCsvBuilder
  def initialize(course)
    @course = course
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    @course.course_stat.stats_hash['www.wikidata.org'].each do |revision_type, count|
      csv_data << [revision_type, count]
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  CSV_HEADERS = %w[
    revision_type
    count
  ].freeze
end
