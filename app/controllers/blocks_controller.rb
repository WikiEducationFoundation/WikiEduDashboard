# frozen_string_literal: true

class BlocksController < ApplicationController
  respond_to :json

  def destroy
    block = Block.find(params[:id]).destroy
    course = block.course
    if course.approved? 
      DeletedTimelineAlertManager.new(course)
      DeletedTimelineAlertManager.create_alerts
    end
    render plain: '', status: :ok
  end
end
