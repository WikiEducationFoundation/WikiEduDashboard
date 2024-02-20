# frozen_string_literal: true

#= Controller for home page
class HomeController < ApplicationController
  respond_to :html
  layout 'home'

  def index
    campaign_slug = CampaignsPresenter.default_campaign_slug
    @presenter = CoursesPresenter.new(current_user:, campaign_param: campaign_slug)
    @stats = fetch_statistics
    if @stats.nil?
      # Dummy data when stats are not available initially or while running rspec tests
      @stats = {
        wiki_edu_courses: '6,200',
        students: '126,000',
        worked_articles: '141,000',
        added_words: '106',
        total_pages: '361,000',
        volumes: '77',
        article_views: '438',
        universities: '800'
      }
    end
  end

  def fetch_statistics
    Rails.cache.fetch('impact_stats', expires_in: 12.hours) do
      impact_stats = Setting.find_by(key: 'impact_stats')&.value
      impact_stats
    end
  end
end
