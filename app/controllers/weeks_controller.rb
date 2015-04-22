#= Controller for week functionality
class WeeksController < ApplicationController
  respond_to :html, :json

  def index
    @course = Course.find_by_slug(params[:course_id])
    respond_to do |format|
      format.json { render json: @course.weeks }
    end
  end

  def week_params
    params.require(:week).permit(:title)
  end

  def create
    @course = Course.find_by_slug(params[:course_id])
    @week = Week.create(week_params)
    @course.weeks << @week
    redirect_to timeline_path(id: @course.slug)
  end

  def new
    @course = Course.find_by_slug(params[:course_id])
    respond_with(@course)
  end
end
