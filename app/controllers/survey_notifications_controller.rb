# frozen_string_literal: true

class SurveyNotificationsController < ApplicationController
  before_action :require_signed_in
  before_action :set_notification

  def update
    if @notification.update(notification_params)
      render json: { success: true }
    else
      render json: { error: @notification.errors }
    end
  end

  private

  def set_notification
    @notification = SurveyNotification.find(params[:survey_notification][:id])
    raise NotPermittedError unless @notification.courses_user&.user_id == current_user.id
  end

  def notification_params
    params.require(:survey_notification).permit(:dismissed, :completed)
  end
end
