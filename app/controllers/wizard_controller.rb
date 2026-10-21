# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wizard_timeline_manager"
require_dependency "#{Rails.root}/lib/wizard_block_catalog"
require_dependency "#{Rails.root}/lib/wizard_logic_state"

#= Controller for timeline functionality
class WizardController < ApplicationController
  respond_to :html, :json
  before_action :require_permissions,
                only: [:submit_wizard]
  before_action :require_admin_permissions,
                only: [:wizard_blocks]

  ##############
  # ADW config #
  ##############
  def wizard_index
    content_path = "#{Rails.root}/config/wizard/wizard_index.yml"
    all_content = YAML.safe_load(File.read(File.expand_path(content_path, __FILE__)))
    # Additional wizard options can be added conditionally to all_content, such as
    # a 'from scratch' option that was previously enabled for returning instructors.
    respond_to do |format|
      format.json { render json: all_content.to_json }
    end
  end

  def wizard
    wizard_id = params[:wizard_id]
    content_path = "#{Rails.root}/config/wizard/#{wizard_id}/wizard.yml"
    all_content = YAML.safe_load(File.read(File.expand_path(content_path, __FILE__)))
    respond_to do |format|
      format.json { render json: all_content.to_json }
    end
  end

  # The catalog of standard blocks this wizard can build, for an admin putting
  # one into a timeline after the fact. Each entry is annotated with whether it
  # matches how the course was set up — :yes, :no, or :unknown where the wizard
  # answer it depends on was never persisted (see WizardLogicState).
  def wizard_blocks
    catalog = WizardBlockCatalog.new(params[:wizard_id])
    course = Course.find_by!(slug: params[:course_id])
    logic = WizardLogicState.new(course, params[:wizard_id])
    titles = Block.where(week_id: Week.where(course_id: course.id).select(:id)).pluck(:title)
    render json: {
      blocks: catalog.blocks.map { |entry| annotate(entry, logic, titles) },
      unknown_logic_keys: logic.unknown_keys(catalog.condition_keys)
    }
  rescue WizardTimelineManager::InvalidWizardError => e
    render json: { error: e.message }, status: :not_found
  end

  ##################
  # Wizard methods #
  ##################
  def wizard_params
    params.permit(wizard_output: {
                    output: [],
                    logic: [],
                    tags: %i[key tag]
                  })
  end

  def submit_wizard
    @course = Course.find_by(slug: params[:course_id])
    wizard_id = params[:wizard_id]
    WizardTimelineManager.update_timeline_and_tags(@course, wizard_id, wizard_params)
    # JBuilder will not render weeks for previous-empty course without this...
    @course = Course.find_by(slug: params[:course_id])
    sync_lti_line_items_if_bound
  end

  private

  def annotate(entry, logic, existing_titles)
    entry.merge(match: logic.verdict_for(entry[:conditions]),
                in_timeline: existing_titles.include?(entry[:title]))
  end

  # If this course is bound to a Canvas placement via LTIAAS, the new
  # timeline shape changes which gradebook columns the binding should own.
  # Fire-and-forget; the worker has its own idempotency lock.
  def sync_lti_line_items_if_bound
    return unless Features.canvas_integration?

    binding = LtiCourseBinding.find_by(course_id: @course&.id)
    return unless binding

    LtiLineItemSyncWorker.perform_async(binding.id)
  end
end
