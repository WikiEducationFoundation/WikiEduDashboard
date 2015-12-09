#= Controller for onboarding
class OnboardingController < ApplicationController
  respond_to :html, :json
  layout 'onboarding'

  def index
    # Require authentication
    if !user_signed_in?
      redirect_to root_path
      return
    end
  end

end
