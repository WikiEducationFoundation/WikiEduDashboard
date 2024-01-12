# frozen_string_literal: true
require Rails.root.join('lib/alerts/check_timeline_alert_manager')
class WeeksController < ApplicationController
  respond_to :json

  def destroy
    week = Week.find(params[:id]).destroy
    course = week.course
    CheckTimelineAlertManager.new(course)
    render plain: '', status: :ok
  end
end
