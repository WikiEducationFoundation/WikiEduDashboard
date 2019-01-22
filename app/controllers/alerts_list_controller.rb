# frozen_string_literal: true

# Controller for showing Alert records
class AlertsListController < ApplicationController
  layout 'admin'
  before_action :check_user_auth

  def index
    alert_type = params[:type]
    user_id = params[:user_id]

    @alerts = Alert.order(id: :desc)
    @alerts = @alerts.where(type: alert_type) if alert_type
    @alerts = @alerts.where(user_id: user_id) if user_id
    @alerts = @alerts.first(100)

    respond_to do |format|
      format.html { render }
      format.json do
        render json: { alerts: @alerts }
      end
    end
  end

  def show
    @alert = Alert.find(params[:id])
  end

  private

  def check_user_auth
    return if current_user&.admin?
    flash[:notice] = "You don't have access to that page."
    redirect_to root_path
  end
end
