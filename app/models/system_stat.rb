# frozen_string_literal: true

# == Schema Information
#
# Table name: system_stats
#
#  id                        :bigint           not null, primary key
#  snapshot_date              :date             not null
#  total_edits               :bigint           default(0)
#  total_article_views       :bigint           default(0)
#  total_articles_improved   :integer          default(0)
#  total_articles_created    :integer          default(0)
#  active_programs_count     :integer          default(0)
#  archived_programs_count   :integer          default(0)
#  new_editors_count         :integer          default(0)
#  new_editors_count_with_preregistration :integer default(0)
#  active_facilitators_count :integer          default(0)
#  total_characters_added    :bigint           default(0)
#  wiki_stats                :text(65535)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#

# Stores daily snapshots of system-wide metrics across all non-private programs.
# Populated by SystemStatUpdateWorker (sidekiq-cron, daily).
# Serves the System Stats dashboard and JSON API.
class SystemStat < ApplicationRecord
  serialize :wiki_stats, type: Hash

  validates :snapshot_date, presence: true, uniqueness: true

  scope :latest, -> { order(snapshot_date: :desc).limit(1) }
  scope :for_date_range, ->(start_date, end_date) {
    where(snapshot_date: start_date..end_date).order(:snapshot_date)
  }

  # Returns the most recent snapshot, or nil if none exist.
  def self.current
    latest.first
  end

  # Returns the last N months of snapshots for trend charts.
  def self.recent_months(months = 12)
    for_date_range(months.months.ago.to_date, Date.today)
  end
end
