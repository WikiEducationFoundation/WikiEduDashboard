# frozen_string_literal: true

class WeeksController < ApplicationController
  respond_to :json

  def destroy
    Week.find(params[:id]).destroy
    course = week.course
    if course.approved? 
      DeletedTimelineAlertManager.new(course)
      DeletedTimelineAlertManager.create_alerts
    end
    render plain: '', status: :ok
  end
end
