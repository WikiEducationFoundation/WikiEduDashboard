# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/retention_report_card_row"
require 'csv'

# The report card for a campaign's Scholars & Scientists courses: one row per
# FellowsCohort course, oldest first, plus a totals row, in the columns of the
# staff spreadsheet this page replaces. Built entirely from stored data (courses
# columns and RetentionStat rows); nothing is fetched on request.
class RetentionReportCard
  # `stage` is the checkpoint (RetentionStudentStats.stage) at which the figure
  # becomes final: 1 for the during-course figures, 2 for the 30-day ones, 3 for
  # the survival ones. The page uses it to tell a pending cell from one that
  # will never fill in (RetentionReportCardRow#reached?).
  Column = Struct.new(:group, :key, :format, :stage)

  # Column keys double as RetentionReportCardRow methods and as the locale keys
  # of the headers (report_cards.columns.*).
  COLUMNS = [
    Column.new(:general, :number, :text),
    Column.new(:general, :title, :text),
    Column.new(:general, :instructors, :text),
    Column.new(:during, :participants, :integer, 1),
    Column.new(:during, :long_term_wikipedians, :integer, 1),
    Column.new(:during, :sessions_during, :integer, 1),
    Column.new(:during, :avg_sessions_during, :decimal, 1),
    Column.new(:during, :zero_edit_participants, :integer, 1),
    Column.new(:during, :uploads, :integer, 1),
    Column.new(:during, :avg_uploads, :decimal, 1),
    Column.new(:during, :words, :integer, 1),
    Column.new(:during, :avg_words, :integer, 1),
    Column.new(:after, :editors_after_course, :integer, 2),
    Column.new(:after, :pct_active_editors_after, :percent, 2),
    Column.new(:after, :avg_days_to_return, :decimal, 2),
    Column.new(:after, :avg_sessions_after, :decimal, 2),
    Column.new(:after, :any_survival_edits, :integer, 3),
    Column.new(:after, :any_survival_edits_returning, :integer, 3),
    Column.new(:after, :survivors, :integer, 3),
    Column.new(:after, :survivors_returning, :integer, 3)
  ].freeze

  attr_reader :campaign, :rows, :totals

  def initialize(campaign)
    @campaign = campaign
    courses = campaign.courses.where(type: 'FellowsCohort')
                      .includes(:instructors, :retention_stats).order(:start).to_a
    @rows = courses.each_with_index.map do |course, index|
      RetentionReportCardRow.new([course], number: index + 1)
    end
    @totals = RetentionReportCardRow.new(courses)
  end

  # Column groups and how many columns each spans, for the two-level header.
  def groups
    COLUMNS.group_by(&:group).transform_values(&:size)
  end

  def to_csv
    CSV.generate do |csv|
      csv << COLUMNS.map { |column| I18n.t("report_cards.columns.#{column.key}") }
      (rows + [totals]).each do |row|
        csv << COLUMNS.map { |column| row.public_send(column.key) }
      end
    end
  end
end
