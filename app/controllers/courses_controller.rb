class CoursesController < ApplicationController
  def index
    @courses = Course.all.where(listed: true).order(:title)
    if params[:cohort].present?
      @cohort = params[:cohort]
      @courses = @courses.cohort(@cohort)
    else
      @cohort = "spring_2015"
    end
    @untrained = @courses.reduce(0) {|sum, c| sum = sum + c.users.student.where(trained: false).count }
  end

  def show
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @students = @course.users.student.order(character_sum: :desc).limit(4)
    @volunteers = @course.users.online_volunteer + @course.users.campus_volunteer
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
    @volunteers = @course.users.online_volunteer + @course.users.campus_volunteer
    @courses_users = @course.courses_users
  end

  def articles
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @articles = @course.articles.order(:title)
    @volunteers = @course.users.online_volunteer + @course.users.campus_volunteer
    @courses_users = @course.courses_users
  end
end
