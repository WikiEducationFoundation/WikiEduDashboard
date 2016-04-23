#= Controller for Recent Activity features
class RecentActivityController < ApplicationController
  def index; end

  def refresh_report_urls
    require "#{Rails.root}/lib/importers/plagiabot_importer"
    PlagiabotImporter.import_report_urls

    redirect_to '/recent-activity/plagiarism'
  end
 
  def plagiarism_report
    ithenticate_id = params[:ithenticate_id]
    report_url = PlagiabotImporter.api_get_url(ithenticate_id: ithenticate_id)
    redirect_to report_url
  end
end
