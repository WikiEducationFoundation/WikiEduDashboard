#= Controller for week functionality
class WeeksController < ApplicationController
  respond_to :html, :json

  def new
    @course = Course.find_by_slug(params[:course_id])
    respond_with(@course)
  end

  def index
    @course = Course.find_by_slug(params[:course_id])
    respond_to do |format|
      format.json { render json: @course.weeks.as_json(include: :blocks) }
    end
  end

  def week_params
    params.require(:week).permit(:id, :title)
  end

  def create
    @course = Course.find_by_slug(params[:course_id])
    @week = Week.create(week_params)
    @course.weeks << @week
    respond_to do |format|
      format.json { render json: @course.weeks.as_json(include: :blocks) }
      format.html { redirect_to timeline_path(id: @course.slug) }
    end
  end

  def update
    @week = Week.find(params[:id])
    @week.update week_params
    respond_to do |format|
      format.json { render json: @week.course.weeks.as_json(include: :blocks) }
    end
  end

  def destroy
    @week = Week.find(params[:id])
    @course = @week.course
    Block.destroy @week.blocks.map(&:id)
    @week.destroy
    respond_to do |format|
      format.json { render json: @course.weeks.as_json(include: :blocks) }
    end
  end
end
