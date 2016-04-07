class SurveyNotificationsController < ApplicationController
  before_action :require_admin_permissions

  def update
    @notification = SurveyNotification.find(params[:survey_notification][:id])
    if @notification.update(notification_params)
      render json: { success: true }
    else
      render json: { error: @notification.errors }
    end
  end

  def notification_params
    params.require(:survey_notification).permit(:id, :dismissed, :completed)
  end
end
