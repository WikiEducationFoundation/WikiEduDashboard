# frozen_string_literal: true
require "#{Rails.root}/lib/alerts/check_timeline_manager"
class BlocksController < ApplicationController
  respond_to :json

  def destroy
    course = Block.find(params[:id]).course
    Block.find(params[:id]).destroy
    CheckTimelineManager.new(course)
    render plain: '', status: :ok
  end
end
