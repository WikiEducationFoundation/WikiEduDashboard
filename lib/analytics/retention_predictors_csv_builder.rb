# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/retention_student_stats"
require_dependency "#{Rails.root}/lib/analytics/retention_summary_block"
require 'csv'

# Builds the "Retention predictors" CSV report for a course (currently the
# Scholars & Scientists / FellowsCohort program): a per-course summary block
# followed by a per-student detail block, from the metrics RetentionStudentStats
# computes (see there for what each metric means and when it becomes final).
#
# The summary block aggregates by participant history — long-term Wikipedians
# excluded, returning participants in a column of their own; see
# RetentionSummaryBlock. The detail block reports all three groups alike, so an
# excluded participant is still visible as somebody who took part.
class RetentionPredictorsCsvBuilder
  DETAIL_HEADERS = ['username', 'sessions during course', 'days to first independent edit',
                    'sessions in 30 days after course', 'edits in days 60-90',
                    'edits before course', 'long-term Wikipedian (500+ edits)',
                    'prior courses', 'prior course slugs'].freeze

  def initialize(course)
    @course = course
  end

  def generate_csv
    stats = RetentionStudentStats.new(@course).stats
    CSV.generate do |csv|
      RetentionSummaryBlock.new(stats).rows.each { |row| csv << row }
      csv << []
      detail_rows(stats).each { |row| csv << row }
    end
  end

  private

  def detail_rows(stats)
    rows = stats.map do |s|
      [s[:username], s[:sessions_during], s[:days_to_return], s[:sessions_after], s[:edits_60_90],
       s[:prior_edits], (s[:long_term] ? 'yes' : nil), s[:prior_courses], s[:prior_course_slugs]]
    end
    [['Per-student detail'], DETAIL_HEADERS, *rows]
  end
end
