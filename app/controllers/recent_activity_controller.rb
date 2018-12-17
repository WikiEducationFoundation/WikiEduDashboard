# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/plagiabot_importer"

#= Controller for Recent Activity features
class RecentActivityController < ApplicationController
  def index; end

  def plagiarism_report
    unless current_user
      # If user is not logged in, send user to login and redirect back to the
      # report upon successful login.
      redirect_to "/users/auth/mediawiki?origin=#{CGI.escape(request.fullpath)}"
      return
    end

    ithenticate_id = params[:ithenticate_id]
    report_url = PlagiabotImporter.api_get_url(ithenticate_id: ithenticate_id)
    redirect_to report_url
  end
end
