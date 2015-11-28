#= Controller for onboarding
class OnboardingController < ApplicationController
  respond_to :html
  layout 'onboarding'

  def index

    # Require authentication
    if !user_signed_in?
      redirect_to '/'
      return
    end

    # Redirect to dashboard if they're already onboarded
    if current_user.onboarded
      redirect_to '/courses'
    end

  end

end
