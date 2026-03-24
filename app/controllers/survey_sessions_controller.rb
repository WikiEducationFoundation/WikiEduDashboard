# frozen_string_literal: true

class SurveySessionsController < ApplicationController
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
    record = SurveySession.find(params[:tracking_id])
    record.update!(completed_at: Time.zone.now)
    render json: { duration_in_seconds: record.duration_in_seconds }
  end
end
