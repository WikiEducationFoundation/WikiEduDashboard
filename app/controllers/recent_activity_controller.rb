#= Controller for Recent Activity features
class RecentActivityController < ApplicationController
  def index; end

  def refresh_report_urls
    require "#{Rails.root}/lib/importers/plagiabot_importer"
    PlagiabotImporter.import_report_urls

    redirect_to '/recent-activity/plagiarism'
  end
end
