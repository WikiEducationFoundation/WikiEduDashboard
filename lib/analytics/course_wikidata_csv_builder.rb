# frozen_string_literal: true

require 'csv'

class CourseWikidataCsvBuilder
  def initialize(course)
    @course = course
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    csv_data << stat_row if @course.course_stat && @course.home_wiki.project == 'wikidata'

    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  def stat_row
    hash_stats = @course
                 .course_stat.stats_hash['www.wikidata.org']
                 .merge({ 'course name' => @course.title })
    CSV_HEADERS.map { |elmnt| hash_stats.fetch elmnt, 0 }
  end

  CSV_HEADERS = [
    'course name',
    'claims created',
    'claims changed',
    'claims removed',
    'items created',
    'lexeme items created',
    'labels added',
    'labels changed',
    'labels removed',
    'descriptions added',
    'descriptions changed',
    'descriptions removed',
    'aliases added',
    'aliases changed',
    'aliases removed',
    'merged from',
    'merged to',
    'interwiki links added',
    'interwiki links removed',
    'redirects created',
    'reverts performed',
    'restorations performed',
    'items cleared',
    'qualifiers added',
    'other updates',
    'unknown',
    'no data',
    'total revisions'
  ].freeze
end
