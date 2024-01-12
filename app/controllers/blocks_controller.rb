# frozen_string_literal: true
require Rails.root.join('lib/alerts/check_timeline_alert_manager')
class BlocksController < ApplicationController
  respond_to :json

  def destroy
    block = Block.find(params[:id]).destroy
    course = block.course
    CheckTimelineAlertManager.new(course)
    render plain: '', status: :ok
  end
end
