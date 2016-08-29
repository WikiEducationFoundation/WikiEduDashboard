# frozen_string_literal: true

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
    @user.update_attributes(real_name: params[:real_name],
                            email: params[:email],
                            permissions: @permissions,
                            onboarded: true)

    render nothing: true, status: 204
  end

  private

  def set_new_permissions
    @permissions = @user.permissions
    # No instructor permission is the default.
    return unless params[:instructor] == true
    # Do not downgrade admins' permissions.
    return if @permissions == User::Permissions::ADMIN

    @permissions = User::Permissions::INSTRUCTOR
  end

  def validate_params
    [:real_name, :email, :instructor].each_with_object(params) do |key, obj|
      obj.require(key)
    end
  end
end
