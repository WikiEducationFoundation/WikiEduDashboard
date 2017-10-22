# frozen_string_literal: true

require "#{Rails.root}/lib/importers/plagiabot_importer"

#= Controller for Recent Activity features
class RecentActivityController < ApplicationController
  def index; end

  def plagiarism_report
    require_signed_in
    ithenticate_id = params[:ithenticate_id]
    report_url = PlagiabotImporter.api_get_url(ithenticate_id: ithenticate_id)
    redirect_to report_url
  end
end
