require "#{Rails.root}/lib/revision_analytics_service"

# Controller for Revision Analytics features
class RevisionAnalyticsController < ApplicationController
  respond_to :json

  def dyk_eligible
    @articles = RevisionAnalyticsService.dyk_eligible
  end

  def suspected_plagiarism
    @revisions = RevisionAnalyticsService.suspected_plagiarism
  end
end
