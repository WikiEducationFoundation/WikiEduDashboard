class CoursesController < ApplicationController
  def index
    @courses = Course.all
    @users = User.all
    @courses_users = CoursesUsers.all
    @articles_courses = ArticlesCourses.all
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
