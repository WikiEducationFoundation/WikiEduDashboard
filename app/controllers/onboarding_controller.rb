#= Controller for onboarding
class OnboardingController < ApplicationController
  respond_to :html, :json
  layout 'onboarding'

  def index
    # Require authentication
    redirect_to root_path unless user_signed_in?
  end
end
