# frozen_string_literal: true

#= Controller for campaign/course functionality
class ExploreController < ApplicationController
  respond_to :html

  def index
    # 'cohort' is the old name for campaign. We accept 'cohort' as an alternative
    # Redirect to new campaign overview page if a parameter is given, for backwards compatibility
    campaign_param = params[:campaign] || params[:cohort]
    redirect_to campaign_path(campaign_param) if campaign_param
    campaign = Campaign.find_by(slug: CampaignsPresenter.default_campaign_slug)
    redirect_to '/' unless campaign
  end
end
