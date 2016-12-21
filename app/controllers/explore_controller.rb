# frozen_string_literal: true
#= Controller for campaign/course functionality
class ExploreController < ApplicationController
  respond_to :html

  def index
    # 'cohort' is the old name for campaign. We accept 'cohort' as an alternative
    # Redirect to new campaign overview page if a parameter is given, for backwards compatibility
    if campaign = params[:campaign] || params[:cohort]
      redirect_to campaign_path(campaign)
    end

    @presenter = CoursesPresenter.new(current_user, ENV['default_campaign'])
  end
end
