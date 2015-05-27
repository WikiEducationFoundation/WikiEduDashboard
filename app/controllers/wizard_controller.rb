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
                    logic: []
                  })
  end

  def submit_wizard
    @course = Course.find_by_slug(params[:course_id])

    # Get the content to be added as a result of the wizard answers
    wizard_id = params[:wizard_id]
    content_path =
      "#{Rails.root}/config/wizard/#{wizard_id}/content.yml"
    all_content = YAML.load(File.read(File.expand_path(content_path, __FILE__)))
    output = wizard_params['wizard_output']['output'] || []
    logic = wizard_params['wizard_output']['logic'] || []
    content_groups = output.map do |content_key|
      all_content[content_key]
    end

    # Build a timeline array
    # Quirk: Will stuff blocks into last week if averages don't line up nicely
    timeline = build_timeline(content_groups, @course)

    # Create and save week/block objects based on the object generated above
    save_timeline(timeline, logic)

    respond_to do |format|
      format.json do
        render json: @course.to_json
      end
    end
  end

  def build_timeline(content_groups, course)
    # Add up the total weight of the content to be added
    total_weight = content_groups.reduce(0) do |tw, cg|
      tw + (cg.map { |w| w['weight'] }).inject(0, :+)
    end

    # Find average weight per week to aim for
    total_weeks = ((course.end - course.start) / 7).floor
    average_weight = total_weight / total_weeks

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
    timeline
  end

  def save_timeline(timeline, logic)
    new_week = nil
    week_finished = false
    timeline.each do |week|
      week[:blocks].each_with_index do |block, i|
        # Skip blocks with unmet 'if' dependencies
        if_met = !block.key?('if')
        block_if = block['if'].is_a?(Array) ? block['if'] : [block['if']]
        if_met ||= block_if.reduce(true) do |met, dep|
          met && logic.include?(dep)
        end
        next unless if_met

        # Skip blocks with unmet 'unless' dependencies
        unless_met = !block.key?('unless')
        block_unless = block['unless'].is_a?(Array) ? block['unless'] : [block['unless']]
        unless_met ||= block_unless.reduce(true) do |met, dep|
          met && !logic.include?(dep)
        end
        next unless unless_met

        if new_week.nil? || (!new_week.blocks.blank? && week_finished)
          new_week = Week.create(course_id: @course.id)
          week_finished = false
        end
        block['week_id'] = new_week.id
        block['order'] = i
        Block.create(block.except('if', 'unless'))
      end
      week_finished = true
    end
  end
end
