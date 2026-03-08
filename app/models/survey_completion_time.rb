# frozen_string_literal: true

# == Schema Information
#
# Table name: survey_completion_times
#
#  id                     :bigint           not null, primary key
#  survey_id              :integer          not null
#  user_id                :integer          not null
#  survey_notification_id :integer
#  started_at             :datetime         not null
#  completed_at           :datetime
#  duration_in_seconds    :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class SurveyCompletionTime < ApplicationRecord
  belongs_to :survey
  belongs_to :user
  belongs_to :survey_notification, optional: true

  scope :completed, -> { where.not(completed_at: nil) }

  def duration_in_seconds
    return nil unless completed_at && started_at
    (completed_at - started_at).to_i
  end
end
