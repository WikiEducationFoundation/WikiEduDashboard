# frozen_string_literal: true

# Controller for showing Alert records
class AlertsListController < ApplicationController
  layout 'admin'

  def index
    check_user_auth
    @alerts = Alert.order(id: :desc).first(100)
  end

  private

  def check_user_auth
    return if current_user&.admin?
    flash[:notice] = "You don't have access to that page."
    redirect_to root_path
  end
end
