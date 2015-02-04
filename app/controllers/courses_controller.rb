class CoursesController < ApplicationController
  def index
    if params[:cohort].present?
      @cohort = params[:cohort]
    else
      @cohort = "spring_2015"
    end
    @courses = Course.cohort(@cohort).where(listed: true).order(:title)
    @untrained = @courses.sum(:untrained_count)
    @trained = @courses.sum(:user_count) - @courses.sum(:untrained_count)
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
    @courses_users = @course.courses_users.includes(user: {assignments: :article}).where(users: {role: 0}).order("users.wiki_id")
    @volunteers = @course.users.online_volunteer + @course.users.campus_volunteer
  end

  def articles
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @articles_courses = @course.articles_courses.includes(:article).order("articles.title")
    @volunteers = @course.users.online_volunteer + @course.users.campus_volunteer
  end
end
