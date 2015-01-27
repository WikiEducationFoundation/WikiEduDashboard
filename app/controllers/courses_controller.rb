class CoursesController < ApplicationController
  def index
    @courses = Course.all.where(listed: true).order(:title)
    if params[:cohort].present?
      @cohort = params[:cohort]
      @courses = @courses.cohort(@cohort)
    end
  end

  def show
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @students = @course.users.student.order(character_sum: :desc).limit(4)
    @courses_users = @course.courses_users
    @articles = @course.articles.order(:title).limit(4)
  end

  def recent
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @revisions = @course.revisions.order(date: :desc).limit(20)
  end

  def students
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @students = @course.users.student.order(:wiki_id)
  end

  def articles
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @articles = @course.articles.order(:title)
  end
end
