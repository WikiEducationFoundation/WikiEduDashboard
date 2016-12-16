# frozen_string_literal: true
#= Controller for course functionality
class ExploreController < ApplicationController
  respond_to :html

  def index
    # 'cohort' is the old name for campaign. We accept 'cohort' as an alternative
    # parameter to keep old incoming links from breaking.
    campaign = params[:campaign] || params[:cohort] || ENV['default_campaign']
    @presenter = CoursesPresenter.new(current_user, 'none')
    @campaigns = Campaign.active
    return unless @presenter.campaign.nil?
    raise ActionController::RoutingError.new('Not Found'), 'Campaign does not exist'
  end
end
