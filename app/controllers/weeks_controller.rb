# frozen_string_literal: true

class WeeksController < ApplicationController
  respond_to :json

  def destroy
    puts 1
    course = Week.find(params[:id]).course
    puts Week.find(params[:id]).inspect
    Week.find(params[:id]).destroy
    if course.approved? 
      DeletedTimelineAlertManager.new(course)
    end
    render plain: '', status: :ok
  end
end
