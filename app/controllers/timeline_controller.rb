require "#{Rails.root}/lib/wiki_edits"

#= Controller for timeline functionality
class TimelineController < ApplicationController
  respond_to :html, :json
  before_action :require_permissions,
                only: [:update_timeline]

  ########################
  # Week + Block Methods #
  ########################
  def timeline_params
    permitted = { weeks: [
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
    ] }
    # If the API sends [] as training_module_ids (which it will when they're cleared)
    # then permit :training_module_ids in a way that'll accept a nil value
    # (if not, ActiveRecord converts it to nil, and it doesn't get whitelisted;
    # see http://guides.rubyonrails.org/security.html#unsafe-query-generation and
    # https://github.com/rails/rails/issues/13766#issuecomment-32730118).
    weeks = params[:weeks]
    weeks.each do |week|
      next if week[:blocks].nil?
      week[:blocks].each do |block|
        blocks_index = 3
        if block[:training_module_ids].nil?
          permitted[:weeks][blocks_index][:blocks] << :training_module_ids
        else
          permitted[:weeks][blocks_index][:blocks] << { training_module_ids: [] }
        end
      end
    end
    params.permit(permitted)
  end

  def update_util(model, object)
    if object['id'].nil?
      model.create object
    elsif object.key?(:deleted) && object['deleted']
      model.destroy object['id']
    else
      object.delete('deleted') if object['deleted'] == false
      model.update object['id'], object
    end
  end

  def update_timeline
    @course = Course.find_by_slug(params[:course_id])
    Array.wrap(timeline_params['weeks']).each do |week|
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
    @week.course.reorder_weeks

    return if week['deleted'] || blocks.blank?
    blocks.each do |block|
      update_block block
    end
  end

  DEFAULT_BLOCK_POINTS = 10
  def update_block(block)
    gradeable = block['gradeable']
    block.delete 'gradeable'
    block['week_id'] = @week.id
    @block = update_util Block, block

    return if block['deleted'] || gradeable.nil?
    gradeable['gradeable_item_id'] = @block.id
    gradeable['gradeable_item_type'] = 'block'
    gradeable['points'] = gradeable['points'] || DEFAULT_BLOCK_POINTS
    @gradeable = update_util Gradeable, gradeable
    gradeable_id = Gradeable.exists?(@gradeable.id) ? @gradeable.id : nil
    @block.update(gradeable_id: gradeable_id)
  end
end
