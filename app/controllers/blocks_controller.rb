# frozen_string_literal: true
require "#{Rails.root}/lib/alerts/check_timeline_manager"
class BlocksController < ApplicationController
  respond_to :json

  def destroy
    block = Block.find(params[:id]).destroy
    course = block.course
    CheckTimelineManager.new(course)
    render plain: '', status: :ok
  end
end
