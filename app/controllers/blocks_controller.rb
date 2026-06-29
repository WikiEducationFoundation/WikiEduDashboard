# frozen_string_literal: true
require "#{Rails.root}/lib/alerts/check_timeline_alert_manager"
class BlocksController < ApplicationController
  respond_to :json
  before_action :require_edit_permissions

  def destroy
    @block.destroy
    CheckTimelineAlertManager.new(@block.course)
    render plain: '', status: :ok
  end

  private

  def require_edit_permissions
    require_signed_in
    @block = Block.find(params[:id])
    raise NotPermittedError unless current_user.can_edit?(@block.course)
  end
end
