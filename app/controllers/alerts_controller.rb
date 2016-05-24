class AlertsController < ApplicationController
  before_filter :require_signed_in

  def create
    if Features.enable_get_help_button? == false
      render json: { status: 400 }
      return
    end

    @alert = NeedHelpAlert.new(alert_params)
    @alert.user = current_user

    if @alert.save
      puts "Saved alert: #{@alert}"
      puts "Target user email: #{@alert.target_user.email}"
      @alert.email_target_user if @alert.target_user.email.present?
      puts "Alert sent at: #{@alert.email_sent_at}"
      render json: { status: 200 }
    else
      render json: {
        errors: @alert.errors,
        message: 'unable to create alert'
      }, status: 500
    end
  end

  private

  def alert_params
    params.permit(:target_user_id, :message, :course_id)
  end
end
