# frozen_string_literal: true

# Controller for showing Alert records
class AlertsListController < ApplicationController
  layout 'admin'
  before_action :check_user_auth

  def index
    set_alerts

    respond_to do |format|
      format.html { render }
      format.json do
        @alerts
      end
    end
  end

  def show
    @alert = Alert.find(params[:id])
  end

  private

  LIMIT = 100

  def set_alerts
    alert_type = params[:type]
    user_ids = params[:user_id]

    if params[:course_id]
      course = Course.find_by(id: params[:course_id])
      user_ids = course.instructors.pluck(:id)
    end

    @alerts = Alert.order(id: :desc)
    @alerts = @alerts.where(type: alert_type) if alert_type
    @alerts = @alerts.where(user_id: user_ids) if user_ids
    @alerts = @alerts.first(LIMIT)
  end

  def check_user_auth
    return if current_user&.admin?
    flash[:notice] = t('dashboard.flash_notice')
    redirect_to root_path
  end
end
