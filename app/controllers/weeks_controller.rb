# frozen_string_literal: true

class WeeksController < ApplicationController
  respond_to :json

  def destroy
    Week.find(params[:id]).destroy
    course = week.course
    if course.approved? 
      DeletedTimelineNotification.new(course)
    end
    render plain: '', status: :ok
  end
end
