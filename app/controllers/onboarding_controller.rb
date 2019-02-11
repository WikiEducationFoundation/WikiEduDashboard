# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/alerts/onboarding_alert_manager"

#= Controller for onboarding
class OnboardingController < ApplicationController
  respond_to :html, :json
  layout 'onboarding'

  def index
    # Require authentication
    redirect_to root_path unless user_signed_in?
  end

  # Onboarding sets the user's real name, email address, and optionally instructor permissions
  def onboard
    validate_params
    @user = current_user
    set_new_permissions
    @user.update_attributes(real_name: sanitized_real_name,
                            email: params[:email],
                            permissions: @permissions,
                            onboarded: true)
    CheckWikiEmailWorker.check(user: @user)
    head :no_content
  end

  def supplementary
    head :no_content
    return unless supplementary_response?
    user_name = params[:user_name]
    details = format_details_hash(params)
    response = format_message_response(params)
    OnboardingAlertManager.new.create_alert(user_name, response, details)
  end

  private

  def format_details_hash(params)
    {
      'heard_from' => {
        'answer' => params[:heardFrom],
        'additional' => params[:referralDetails]
      },
      'why_here' => {
        'answer' => params[:whyHere],
        'additional' => params[:otherReason]
      }
    }
  end

  def format_message_response(params)
    referral_details = params[:referralDetails]
    <<~RESPONSE
      HEARD FROM:
      #{params[:heardFrom]} #{"(#{referral_details})" if referral_details}

      WHY HERE:
      #{params[:whyHere]}

      OTHER:
      #{params[:otherReason]}
    RESPONSE
  end

  def supplementary_response?
    params[:heardFrom].present? || params[:whyHere].present? || params[:otherReason].present?
  end

  def set_new_permissions
    @permissions = @user.permissions
    # No instructor permission is the default.
    return unless params[:instructor] == true
    # Do not downgrade admins' permissions.
    return if @user.admin?

    @permissions = User::Permissions::INSTRUCTOR
  end

  def validate_params
    %i[real_name email instructor].each_with_object(params) do |key, obj|
      obj.require(key)
    end
  end

  def sanitized_real_name
    params[:real_name].squish
  end
end
