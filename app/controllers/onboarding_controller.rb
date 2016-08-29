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
    [:real_name, :email, :instructor].each_with_object(params) do |key, obj|
      obj.require(key)
    end

    user = User.find(current_user.id)

    permissions = user.permissions
    if params[:instructor] == true
      permissions = User::Permissions::INSTRUCTOR unless permissions == User::Permissions::ADMIN
    end

    user.update_attributes(real_name: params[:real_name],
                           email: params[:email],
                           permissions: permissions,
                           onboarded: true)

    render nothing: true, status: 204
  end
end
