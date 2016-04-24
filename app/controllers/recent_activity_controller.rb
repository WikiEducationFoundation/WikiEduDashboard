#= Controller for Recent Activity features
class RecentActivityController < ApplicationController
  def index; end

  def plagiarism_report
    ithenticate_id = params[:ithenticate_id]
    report_url = PlagiabotImporter.api_get_url(ithenticate_id: ithenticate_id)
    redirect_to report_url
  end
end
