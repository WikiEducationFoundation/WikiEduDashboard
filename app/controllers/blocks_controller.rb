# frozen_string_literal: true
require "#{Rails.root}/lib/alerts/deleted_timeline_alert_manager"
class BlocksController < ApplicationController
  respond_to :json

  def destroy
    course = Block.find(params[:id]).course
    Block.find(params[:id]).destroy
    DeletedTimelineAlertManager.new(course)
    render plain: '', status: :ok
  end
end
