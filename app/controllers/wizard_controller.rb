#= Controller for timeline functionality
class WizardController < ApplicationController
  respond_to :html, :json
  before_action :require_permissions,
                only: [:submit_wizard]

  ##############
  # ADW config #
  ##############
  def get_wizard_index
    content_path = "#{Rails.root}/config/wizard/wizard_index.yml"
    all_content = YAML.load(File.read(File.expand_path(content_path, __FILE__)))
    respond_to do |format|
      format.json { render json: all_content.to_json }
    end
  end

  def get_wizard
    wizard_id = params[:wizard_id]
    content_path = "#{Rails.root}/config/wizard/wizards/#{wizard_id}_wizard.yml"
    all_content = YAML.load(File.read(File.expand_path(content_path, __FILE__)))
    respond_to do |format|
      format.json { render json: all_content.to_json }
    end
  end

  ##################
  # Wizard methods #
  ##################
  def wizard_params
    params.permit(output: [])
  end

  def submit_wizard
    @course = Course.find_by_slug(params[:course_id])

    # Get the content to be added as a result of the wizard answers
    content_path = "#{Rails.root}/config/wizard/content.yml"
    all_content = YAML.load(File.read(File.expand_path(content_path, __FILE__)))
    content_groups = wizard_params['output'].map do |content_key|
      all_content[content_key]
    end

    # Add up the total weight of the content to be added
    total_weight = content_groups.reduce(0) do |tw, cg|
      tw + (cg.map { |w| w['weight'] }).inject(0, :+)
    end

    # Find average weight per week to aim for
    total_weeks = ((@course.end - @course.start) / 7).floor
    average_weight = total_weight / total_weeks

    # Build a timeline array
    # Quirk: Will stuff blocks into last week if averages don't line up nicely
    timeline = []
    content_groups.each do |cg|       # An array of week collections
      cg.each do |week|               # An array of weeks
        curr_week = timeline[-1]
        weeks_maxed = timeline.size >= total_weeks
        curr_weight = (curr_week || { weight: 0 })[:weight]
        if !curr_week.nil? && (curr_weight <= average_weight || weeks_maxed)
          curr_week[:weight] += week['weight']
          curr_week[:blocks] += week['blocks']
        else
          timeline.push OpenStruct.new(
            weight: week['weight'],
            blocks: week['blocks']
          )
        end
      end
    end

    # Create and save week/block objects based on the object generated above
    timeline.each do |week|
      new_week = Week.create(course_id: @course.id)
      week[:blocks].each_with_index do |block, i|
        block['week_id'] = new_week.id
        block['order'] = i
        Block.create(block)
      end
    end

    respond_to do |format|
      format.json do
        render json: @course.as_json(
          include: { weeks: {
            include: { blocks: { include: :gradeable } }
          } }
        )
      end
    end
  end

end