class AlertsController < ApplicationController
  before_filter :require_signed_in

  def create
    ensure_alerts_are_enabled { return }

    @alert = NeedHelpAlert.new(alert_params)
    @alert.user = current_user

    if @alert.save
      @alert.email_target_user if @alert.target_user.email.present?
      render json: {}, status: 200
    else
      render json: { errors: @alert.errors, message: 'unable to create alert' },
             status: 500
    end
  end

  private

  def ensure_alerts_are_enabled
    return if Features.enable_get_help_button?
    render json: {}, status: 400
    yield
  end

  def alert_params
    params.permit(:target_user_id, :message, :course_id)
  end
end
