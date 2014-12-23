class CoursesController < ApplicationController
  def index
    @courses = Course.all
    @users = User.all
    @revisions = Revision.all
    @articles = Article.all
  end

  def show
    @course = Course.find_by_slug(params[:id])
    @students = @course.users.order(character_sum: :desc).limit(4)
    @articles = @course.articles.order(character_sum: :desc).limit(4)
  end

  def students
    @course = Course.find_by_slug(params[:id])
    @students = @course.users.order(:wiki_id)
  end

  def articles
    @course = Course.find_by_slug(params[:id])
    @articles = @course.articles.order(:title)
  end
end
