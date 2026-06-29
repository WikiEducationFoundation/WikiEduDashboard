# frozen_string_literal: true
require "#{Rails.root}/lib/alerts/check_timeline_alert_manager"
class WeeksController < ApplicationController
  respond_to :json
  before_action :require_edit_permissions

  def destroy
    @week.destroy
    CheckTimelineAlertManager.new(@week.course)
    render plain: '', status: :ok
  end

  private

  def require_edit_permissions
    require_signed_in
    @week = Week.find(params[:id])
    raise NotPermittedError unless current_user.can_edit?(@week.course)
  end
end
