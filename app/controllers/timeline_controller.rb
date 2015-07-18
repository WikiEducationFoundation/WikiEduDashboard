require "#{Rails.root}/lib/wiki_edits"

#= Controller for timeline functionality
class TimelineController < ApplicationController
  respond_to :html, :json
  before_action :require_permissions,
                only: [:update_timeline, :update_gradeables]

  def index
    @course = Course.find_by_slug(params[:course_id])
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
        :duration,
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
    elsif object.key?(:deleted) && object['deleted']
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
    WikiEdits.update_course(@course, current_user)
    render 'timeline'
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
      @gradeable = update_util Gradeable, gradeable
    end
    render 'timeline'
  end
end
