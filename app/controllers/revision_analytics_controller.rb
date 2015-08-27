require "#{Rails.root}/lib/revision_analytics_service"

class RevisionAnalyticsController < ApplicationController
  respond_to :json

  def dyk_eligible
    @articles = Article.joins(:revisions).includes(:revisions).where{ revisions.wp10 > 40 }.where{(namespace == 118) | ((namespace == 2) & (title !~ '%/%'))}
  end

end
