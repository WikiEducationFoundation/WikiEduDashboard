require "#{Rails.root}/lib/revision_analytics_service"

class RevisionAnalyticsController < ApplicationController
  respond_to :json

  def dyk_eligible
    @articles = RevisionAnalyticsService.dyk_eligible
  end

end
