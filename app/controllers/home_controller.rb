# frozen_string_literal: true

#= Controller for home page
class HomeController < ApplicationController
  respond_to :html
  layout 'home'

  def index
    campaign_slug = CampaignsPresenter.default_campaign_slug
    @presenter = CoursesPresenter.new(current_user:, campaign_param: campaign_slug)
    @stats = fetch_statistics
  end

  def fetch_statistics
    Rails.cache.fetch('impact_stats') do
      impact_stats = Setting.find_by(key: 'impact_stats')&.value.presence || {}
      impact_stats
    end
  end
end
