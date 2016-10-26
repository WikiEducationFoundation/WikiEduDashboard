# frozen_string_literal: true
#= Controller for course functionality
class ExploreController < ApplicationController
  respond_to :html

  def index
    campaign = params[:campaign] || ENV['default_campaign']
    @presenter = CoursesPresenter.new(current_user, campaign)
    raise ActionController::RoutingError
      .new('Not Found'), 'Campaign does not exist' unless @presenter.campaign
  end
end
