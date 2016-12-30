# frozen_string_literal: true
#= Controller for campaign/course functionality
class ExploreController < ApplicationController
  respond_to :html

  def index
    # 'cohort' is the old name for campaign. We accept 'cohort' as an alternative
    # Redirect to new campaign overview page if a parameter is given, for backwards compatibility
    campaign = params[:campaign] || params[:cohort]
    redirect_to campaign_path(campaign) if campaign

    @presenter = CoursesPresenter.new(current_user: current_user, campaign_param: ENV['default_campaign'])
  end
end
