#= Controller for block functionality
class BlocksController < ApplicationController
  respond_to :html, :json

  def block_params
    gradeable = params[:block][:is_gradeable]
    gradeable = gradeable == '1' || gradeable == 'true'
    if gradeable
      @points = params[:block][:points] || 10
      if params.key?(:course_id)
        @course = Course.find_by_slug(params[:course_id])
        @gradeable = Gradeable.create(
          gradeable_item_id: @course.id,
          gradeable_item_type: 'course',
          points: @points
        )
      elsif params[:block].key?(:id)
        item_id = params[:block][:id]
        @gradeable = Gradeable.create(
          gradeable_item_id: item_id,
          gradeable_item_type: 'block',
          points: @points
        )
      else
        @gradeable = Gradeable.create(points: @points)
      end
      params[:block][:gradeable_id] = @gradeable.id
    else
      if params[:block].key?(:id)
        @block = Block.find(params[:block][:id])
        Gradeable.find(@block.gradeable_id).destroy
      end
      params[:block][:gradeable_id] = nil
    end

    params.require(:block).permit(
      :title,
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

    respond_to do |format|
      format.json { render json: @week.blocks }
      format.html { redirect_to timeline_path(id: @course.slug) }
    end
  end

  def new
    @course = Course.find_by_slug(params[:course_id])
    @week = Week.find(params[:week_id])
    respond_with(course: @course, week: @week)
  end

  def index
    @week = Week.find(params[:week_id])
    respond_to do |format|
      format.json { render json: @week.blocks }
    end
  end

  def update
    @block = Block.find(params[:id])
    @block.update block_params
    respond_to do |format|
      format.json { render json: @block.week.blocks }
    end
  end

  def destroy
    @week = Block.find(params[:id]).week
    Block.destroy(params[:id])
    respond_to do |format|
      format.json { render json: @week.blocks }
    end
  end
end
