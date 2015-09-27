require "#{Rails.root}/lib/wizard_timeline_manager"

#= Controller for timeline functionality
class WizardController < ApplicationController
  respond_to :html, :json
  before_action :require_permissions,
                only: [:submit_wizard]

  ##############
  # ADW config #
  ##############
  def wizard_index
    content_path = "#{Rails.root}/config/wizard/wizard_index.yml"
    all_content = YAML.load(File.read(File.expand_path(content_path, __FILE__)))
    respond_to do |format|
      format.json { render json: all_content.to_json }
    end
  end

  def wizard
    wizard_id = params[:wizard_id]
    content_path = "#{Rails.root}/config/wizard/#{wizard_id}/wizard.yml"
    all_content = YAML.load(File.read(File.expand_path(content_path, __FILE__)))
    respond_to do |format|
      format.json { render json: all_content.to_json }
    end
  end

  ##################
  # Wizard methods #
  ##################
  def wizard_params
    params.permit(wizard_output: {
                    output: [],
                    logic: [],
                    tags: [:key, :tag]
                  })
  end

  def submit_wizard
    @course = Course.find_by_slug(params[:course_id])
    wizard_id = params[:wizard_id]
    WizardTimelineManager
      .update_timeline_and_tags(@course, wizard_id, wizard_params)
    # JBuilder will not render weeks for previous-empty course without this...
    @course = Course.find_by_slug(params[:course_id])
  end
end
