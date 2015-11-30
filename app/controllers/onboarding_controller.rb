#= Controller for onboarding
class OnboardingController < ApplicationController
  respond_to :html, :json
  layout 'onboarding'

  def index
    # Require authentication
    if !user_signed_in?
      redirect_to '/'
      return
    end

    # Redirect to dashboard if they're already onboarded
    if current_user.onboarded
      redirect_to '/'
    end

  end

  def onboard
    [:id, :real_name, :email].each_with_object(params) do |key, obj|
      obj.require(key)
    end

    user = User.find(params[:id])
    user.real_name = params[:real_name]
    user.email = params[:email]
    user.onboarded = true
    user.save

    render :nothing => true, :status => 204
  end

end
