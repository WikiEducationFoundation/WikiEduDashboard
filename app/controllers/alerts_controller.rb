class AlertsController < ApplicationController
  # before_filter require_signed_in
  skip_before_filter :verify_authenticity_token

  def create
    @alert = Alert.new(alert_params)
    @alert.type = 'NeedHelpAlert'
    @alert.user = current_user

    if @alert.save
      # @alert.email_target_user
      render json: { status: 200 }
    else
      render json: @alert.errors, status: :unprocessable_entity
    end
  end

  private

  def alert_params
    params.permit(:target_user_id, :message)
  end
end
