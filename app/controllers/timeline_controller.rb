#= Controller for timeline functionality
class TimelineController < ApplicationController
  respond_to :html, :json
  before_action :require_permissions,
                only: [:update_timeline, :update_gradeables]

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
