# frozen_string_literal: true
require "#{Rails.root}/lib/alerts/check_timeline_manager"
class WeeksController < ApplicationController
  respond_to :json

  def destroy
    week = Week.find(params[:id]).destroy
    course = week.course
    CheckTimelineManager.new(course)
    render plain: '', status: :ok
  end
end
