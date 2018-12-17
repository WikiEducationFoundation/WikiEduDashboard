# frozen_string_literal: true

#= Controller for timeline functionality
class TimelineController < ApplicationController
  respond_to :html, :json
  before_action :require_permissions, :set_course

  def update_timeline
    Array.wrap(timeline_params['weeks']).each do |week|
      update_week week
    end
    UpdateCourseWorker.schedule_edits(course: @course, editing_user: current_user)
    render 'timeline'
  end

  private

  def set_course
    @course = Course.find_by(slug: params[:course_id])
  end

  ########################
  # Week + Block Methods #
  ########################

  def update_week(week)
    blocks = week['blocks']
    week.delete 'blocks'
    week['course_id'] = @course.id if !week.key?(:course_id) || week['course_id'].nil?
    @week = update_util Week, week
    @week.course.reorder_weeks

    return if blocks.blank?
    blocks.each { |block| update_block(block) }
  end

  def update_block(block)
    block['week_id'] = @week.id
    @block = update_util Block, block
  end

  def update_util(model, object)
    if object['id'].nil?
      model.create object
    else
      model.update object['id'], object
    end
  end

  ##########
  # Params #
  ##########

  def timeline_params
    set_permitted_params_baseline
    # If the API sends [] as training_module_ids (which it will when they're cleared)
    # then permit :training_module_ids in a way that'll accept a nil value
    # (if not, ActiveRecord converts it to nil, and it doesn't get allowed;
    # see http://guides.rubyonrails.org/security.html#unsafe-query-generation and
    # https://github.com/rails/rails/issues/13766#issuecomment-32730118).
    weeks = params[:weeks]
    weeks.each do |week|
      next if week[:blocks].nil?
      week[:blocks].each { |block| permit_training_module_ids(block) }
    end
    params.permit(@permitted)
  end

  def set_permitted_params_baseline
    @permitted = { weeks: [
      :id, :title,
      { blocks: [:id, :title, :kind, :content, :weekday, :week_id,
                 :order, :due_date, :points] }
    ] }
  end

  def permit_training_module_ids(block)
    blocks_index = 2 # this is the index of the blocks array within the weeks array
    @permitted[:weeks][blocks_index][:blocks] << if block[:training_module_ids].nil?
                                                   :training_module_ids
                                                 else
                                                   { training_module_ids: [] }
                                                 end
  end
end
