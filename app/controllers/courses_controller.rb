#= Controller for course functionality
class CoursesController < ApplicationController
  def index
    if params[:cohort].present?
      @cohort = params[:cohort]
    else
      @cohort = 'spring_2015'
    end
    @courses = Course.cohort(@cohort).where(listed: true).order(:title)
    @untrained = @courses.sum(:untrained_count)
    @trained = @courses.sum(:user_count) - @courses.sum(:untrained_count)
  end

  def show
    @course = Course.where(listed: true).find_by_slug(params[:id])
    users = @course.users
    @students = users.role('student').order(character_sum: :desc).limit(4)
    @volunteers = users.role('online_volunteer') + users.role('campus_volunteer')
    @courses_users = @course.courses_users
    @articles = @course.articles.order(:title).limit(4)
  end

  def recent
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @revisions = @course.revisions.order(date: :desc).limit(20)
  end

  def students
    @course = Course.where(listed: true).find_by_slug(params[:id])
    users = @course.users
    @courses_users = @course.courses_users
                     .includes(user: { assignments: :article })
                     .where(role: 0).order('users.wiki_id')
    @volunteers = users.role('online_volunteer') + users.role('campus_volunteer')
  end

  def articles
    @course = Course.where(listed: true).find_by_slug(params[:id])
    users = @course.users
    @articles_courses = @course.articles_courses.live
                        .includes(:article).order('articles.title')
    @volunteers = users.role('online_volunteer') + users.role('campus_volunteer')
  end
end
