class CoursesController < ApplicationController
  def index
    @courses = Course.all
    @users = User.all
    @revisions = Revision.all
    @articles = Article.all
  end

  def show
    @course = Course.find_by_slug(params[:id])
    @students = @course.users
  end

  # def show
  #   @course = Course.find_by_slug(params[:id])
  #   respond_to do |format|
  #     format.html show.html.erb
  #     format.json { render json: @course }
  #   end
  # end
end
