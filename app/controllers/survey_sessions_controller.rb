# frozen_string_literal: true

class SurveySessionsController < ApplicationController
  before_action :require_signed_in

  def start
    record = SurveySession.create!(
      survey_id: params[:survey_id],
      user_id: current_user.id,
      survey_notification_id: params[:survey_notification_id],
      started_at: Time.zone.now
    )
    render json: { tracking_id: record.id }
  end

  def complete
    record = SurveySession.find_by(id: params[:tracking_id], user: current_user)
    return head :not_found unless record
    record.update!(completed_at: Time.zone.now) if record.completed_at.nil?
    render json: { duration_in_seconds: record.duration_in_seconds }
  end
end
