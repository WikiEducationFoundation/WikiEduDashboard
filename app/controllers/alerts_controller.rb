# frozen_string_literal: true
class AlertsController < ApplicationController
  before_action :require_signed_in

  def create
    ensure_alerts_are_enabled { return }

    @alert = NeedHelpAlert.new(alert_params)
    @alert.user = current_user
    Rails.logger.warn alert_params
    # :target_user_id will be nil for the 'dashboard help' option
    set_default_target_user unless alert_params[:target_user_id]

    if @alert.save
      @alert.email_target_user if @alert.target_user&.email.present?
      render json: {}, status: 200
    else
      render json: { errors: @alert.errors, message: 'unable to create alert' }, status: 500
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

  def set_default_target_user
    @alert.target_user_id = User.find_by(username: ENV['technical_help_staff'])&.id
  end
end
