class CoursesController < ApplicationController
  def index
    @courses = Course.all.limit(5)
    @users = User.all
    @revisions = Revision.all
    @articles = Article.all
  end

  def show
    @course = Course.find(params[:id])
    @students = @course.users
  end
end
