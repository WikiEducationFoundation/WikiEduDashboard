# frozen_string_literal: true

#= Controller for home page
class HomeController < ApplicationController
  respond_to :html
  layout 'home'

  def index
    campaign_slug = CampaignsPresenter.default_campaign_slug
    @presenter = CoursesPresenter.new(current_user:, campaign_param: campaign_slug)
  end
end
