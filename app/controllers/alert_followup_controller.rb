# frozen_string_literal: true

class AlertFollowupController < ApplicationController
  before_action :require_signed_in
  before_action :set_alert
  before_action :check_permission

  def show
    render @alert.followup_template
  end

  def update
    response_hash = {
      validation: params['validation'],
      AIs_used: params['ai_tools'],
      AI_other: params['tools_other'],
      used_for: params['ai_used_for'],
      used_for_other: params['use_other'],
      additional_context: params['additional_context']
    }
    @alert.details["followup_#{current_user.username}"] = response_hash
    @alert.save
    flash[:notice] = 'Response saved. Thank you!'
    redirect_to "/alert_followup/#{@alert.id}"
  end

  private

  def set_alert
    @alert = Alert.find params[:id]
  end

  def check_permission
    return if current_user.admin?
    return if current_user.id == @alert.user_id
    return if current_user.instructor?(@alert.course)

    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception
  end
end
