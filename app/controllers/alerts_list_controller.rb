# frozen_string_literal: true

# Controller for showing Alert records
class AlertsListController < ApplicationController
  layout 'admin'
  before_action :check_user_auth

  def index
    @alerts = Alert.order(id: :desc).first(100)
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
