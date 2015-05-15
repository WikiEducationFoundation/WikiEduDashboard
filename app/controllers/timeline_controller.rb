#= Controller for timeline functionality
class TimelineController < ApplicationController
  respond_to :html, :json
  before_action :require_permissions,
                only: [:update_timeline, :update_gradeables, :submit_wizard]

  def index
    @course = Course.find_by_slug(params[:course_id])
    respond_to do |format|
      format.json { render json: @course.weeks.as_json(include: :blocks) }
    end
  end

  ########################
  # Week + Block Methods #
  ########################
  def timeline_params
    params.permit(weeks: [
      :id,
      :deleted,
      :title,
      { blocks: [
        :id,
        :title,
        :kind,
        :content,
        :weekday,
        :week_id,
        :deleted,
        :order,
        :gradeable_id,
        :due_date,
        { gradeable: [
          :id,
          :gradeable_item_id,
          :gradeable_item_type,
          :title,
          :points,
          :deleted
        ] }
      ] }
    ])
  end

  def update_util(model, object)
    if object['id'].nil?
      model.create object
    elsif object['deleted']
      model.destroy object['id']
    else
      model.update object['id'], object
    end
  end

  def update_timeline
    @course = Course.find_by_slug(params[:course_id])
    timeline_params['weeks'].each do |week|
      update_week week
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

  def update_week(week)
    blocks = week['blocks']
    week.delete 'blocks'
    if !week.key?(:course_id) || week['course_id'].nil?
      week['course_id'] = @course.id
    end
    @week = update_util Week, week

    return if week['deleted'] || blocks.blank?
    blocks.each do |block|
      update_block block
    end
  end

  def update_block(block)
    gradeable = block['gradeable']
    block.delete 'gradeable'
    block['week_id'] = @week.id
    @block = update_util Block, block

    return if block['deleted'] || gradeable.nil?
    gradeable['gradeable_item_id'] = @block.id
    gradeable['gradeable_item_type'] = 'block'
    gradeable['points'] = gradeable['points'] || 10
    @gradeable = update_util Gradeable, gradeable
    gradeable_id = Gradeable.exists?(@gradeable) ? @gradeable.id : nil
    @block.update(gradeable_id: gradeable_id)
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

  #####################
  # Gradeable methods #
  #####################
  def gradeable_params
    params.permit(gradeables: [
      :id,
      :title,
      :points
    ])
  end

  def update_gradeables
    @course = Course.find_by_slug(params[:course_id])
    gradeable_params['gradeables'].each do |gradeable|
      @gradeable = Gradeable.find(gradeable['id'])
      @gradeable.update(title: gradeable['title'], points: gradeable['points'])
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
