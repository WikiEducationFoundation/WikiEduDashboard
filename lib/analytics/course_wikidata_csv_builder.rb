# frozen_string_literal: true

require 'csv'
require_dependency "#{Rails.root}/lib/wikidata_summary_parser"

class CourseWikidataCsvBuilder
  def initialize(course)
    @course = course
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    csv_data << ['total wikidata revisions', wikidata_revisions.count]
    wikidata_stats.each do |revision_type, count|
      csv_data << [revision_type, count]
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  private

  CSV_HEADERS = %w[
    revision_type
    count
  ].freeze

  def wikidata_wiki
    @wikidata ||= Wiki.get_or_create(language: nil, project: 'wikidata')
  end

  def wikidata_revisions
    @course.revisions.where(wiki: wikidata_wiki)
  end

  def wikidata_stats
    WikidataSummaryParser.analyze_revisions wikidata_revisions
  end
end
