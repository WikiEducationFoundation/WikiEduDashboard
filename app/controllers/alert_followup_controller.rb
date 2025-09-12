# frozen_string_literal: true

class AlertFollowupController < ApplicationController
  before_action :require_signed_in
  before_action :set_alert
  before_action :check_permission

  def show
    render @alert.followup_template
    # display form
  end

  def update
    # update record
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
