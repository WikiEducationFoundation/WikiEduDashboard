# frozen_string_literal: true

require 'csv'

# Generates CSV exports of daily system statistics snapshots over a date range.
class SystemStatsCsvBuilder
  CSV_HEADERS = %w[
    snapshot_date
    total_edits
    total_article_views
    total_articles_created
    total_articles_improved
    total_characters_added
    active_programs_count
    archived_programs_count
    new_editors_count_with_preregistration
    active_facilitators_count
  ].freeze

  def initialize(start_date: nil, end_date: nil)
    @start_date = parse_date(start_date) || 30.days.ago.to_date
    @end_date = parse_date(end_date) || Time.zone.today
  end

  def generate_csv
    CSV.generate do |csv|
      csv << CSV_HEADERS
      snapshots.each do |snapshot|
        csv << CSV_HEADERS.map { |header| snapshot.public_send(header) }
      end
    end
  end

  private

  def snapshots
    SystemStat.for_date_range(@start_date, @end_date)
              .select(*CSV_HEADERS)
  end

  def parse_date(date_str)
    return if date_str.blank?
    Date.parse(date_str.to_s)
  rescue Date::Error
    nil
  end
end
