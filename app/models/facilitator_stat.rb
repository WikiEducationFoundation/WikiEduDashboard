# frozen_string_literal: true

# == Schema Information
#
# Table name: facilitator_stats
#
#  id                      :bigint           not null, primary key
#  snapshot_date            :date             not null
#  user_id                 :bigint           not null
#  total_programs_count    :integer          default(0)
#  active_programs_count   :integer          default(0)
#  total_edits             :integer          default(0)
#  new_editors_count       :integer          default(0)
#  new_editors_count_with_preregistration :integer default(0)
#  total_students_count    :integer          default(0)
#  total_characters_added  :bigint           default(0)
#  active_in_last_year     :boolean          default(FALSE)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

# Stores weekly snapshots of per-facilitator (instructor/organizer) metrics.
# Populated by FacilitatorStatUpdateWorker (sidekiq-cron, weekly).
# Enables WMF to identify impactful organizers and track facilitator activity.
class FacilitatorStat < ApplicationRecord
  belongs_to :user

  validates :snapshot_date, presence: true
  validates :user_id, uniqueness: { scope: :snapshot_date }

  scope :latest, -> { where(snapshot_date: order(snapshot_date: :desc).pick(:snapshot_date)) }
  scope :for_date_range, ->(start_date, end_date) {
    where(snapshot_date: start_date..end_date).order(:snapshot_date)
  }
  scope :active_facilitators, -> { where(active_in_last_year: true) }

  # Returns the most recent snapshot for all facilitators.
  def self.current
    latest.includes(:user)
  end

  # Returns stats for a specific facilitator over time.
  def self.for_user(user_id)
    where(user_id: user_id).order(:snapshot_date)
  end
end
