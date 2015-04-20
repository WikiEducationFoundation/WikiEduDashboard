#= Controller for block functionality
class BlocksController < ApplicationController
  respond_to :html, :json

  def block_params
    if params[:block][:is_gradeable] == '1'
      @course = Course.find_by_slug(params[:course_id])
      @points = params[:block][:points] || 10
      @gradeable = Gradeable.create(course_id: @course.id, points: @points)
      params[:block][:gradeable_id] = @gradeable.id
    end

    params.require(:block).permit(
      :kind,
      :content,
      :weekday,
      :week_id,
      :gradeable_id
    )
  end

  def create
    @course = Course.find_by_slug(params[:course_id])
    @block = Block.create(block_params)
    @week = Week.find(params[:week_id])
    @week.blocks << @block

    redirect_to timeline_path(id: @course.slug)
  end

  def new
    @course = Course.find_by_slug(params[:course_id])
    @week = Week.find(params[:week_id])
    respond_with(course: @course, week: @week)
  end
end
