# frozen_string_literal: true

class AlertsController < ApplicationController
  before_action :require_signed_in, only: [:create]
  before_action :require_admin_permissions, only: [:resolve]
  before_action :set_alert, only: [:resolve]

  # Creates only NeedHelpAlert. Doesn't require admin permission.
  # Other type of alerts are created via the update cycle, not directly by users.
  def create
    ensure_alerts_are_enabled { return }

    @alert = NeedHelpAlert.new(alert_params)
    @alert.user = current_user
    # :target_user_id will be nil for the 'dashboard help' option
    set_default_target_user unless alert_params[:target_user_id]

    if @alert.save
      email_target_user
      render json: {}, status: 200
    else
      render json: { errors: @alert.errors, message: 'unable to create alert' }, status: 500
    end
  end

  # Resolves alert if it is resolvable? Requires admin permission.
  # Normally, same alerts won't be created for the second time.
  # Resolving alert, allows it to be created for the second time if conditions are met.
  def resolve
    ensure_alert_is_resolvable { return }

    @alert.update resolved: true

    render json: { alert: @alert }
  end

  private

  def email_target_user
    AlertMailerWorker.schedule_email(alert_id: @alert.id) if @alert.target_user&.email.present?
  end

  def ensure_alerts_are_enabled
    return if Features.enable_get_help_button?
    render json: {}, status: 400
    yield
  end

  def ensure_alert_is_resolvable
    return if @alert.resolvable?
    render json: {}, status: 422
    yield
  end

  def alert_params
    params.permit(:target_user_id, :message, :course_id)
  end

  def set_default_target_user
    @alert.target_user_id = SpecialUsers.technical_help_staff&.id
  end

  def set_alert
    @alert = Alert.find(params[:id])
  end
end
