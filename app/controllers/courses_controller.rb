require 'oauth'

#= Controller for course functionality
class CoursesController < ApplicationController
  respond_to :html, :json

  def course_params
    title = params[:course][:title].gsub(' ', '_')
    school = params[:course][:school].gsub(' ', '_')
    term = params[:course][:term].gsub(' ', '_')
    params[:course][:slug] = "#{school}/#{title}_(#{term})"
    params.require(:course).permit(
      :title,
      :description,
      :school,
      :term,
      :slug,
      :subject,
      :expected_students,
      :start,
      :end
    )
  end

  def create
    if Course.exists?(slug: course_params[:slug])
      flash[:notice] = t('course.error.exists')
      redirect_to :back
    else
      @course = Course.create(course_params)
      CoursesUsers.create(user: current_user, course: @course, role: 1)
      redirect_to timeline_path(id: @course.slug)
    end
  end

  def destroy
    @course = Course.find_by_slug(params[:id])
    return unless user_signed_in? && current_user.instructor?(@course)
    @course.destroy
    redirect_to '/'
  end

  def timeline
    @course = Course.find_by_slug(params[:id])
  end

  def index
    if params[:cohort].present?
      @cohort = params[:cohort]
    else
      @cohort = 'spring_2015'
    end

    if user_signed_in?
      @user_courses = current_user.courses
      @user_courses.map do |c|
        c if current_user.instructor?(c) || c.listed
      end
    end

    @courses = Cohort.find_by(slug: @cohort).courses
               .where(listed: true).order(:title)
    @untrained = @courses.sum(:untrained_count)
    @trained = @courses.sum(:user_count) - @courses.sum(:untrained_count)
  end

  def show
    respond_to do |format|
      format.json { render json: @course }
      format.html { redirect_to :overview }
    end
  end

  def update
    @course = Course.find_by_slug(params[:id])
    params = {}
    params['course'] = course_params
    @course.update params
    respond_to do |format|
      format.json { render json: @course }
    end
  end

  def overview
    @course = Course.find_by_slug(params[:id])
    is_instructor = (user_signed_in? && current_user.instructor?(@course))
    unless @course.listed || is_instructor
      fail ActionController::RoutingError 'Not Found' unless @course.nil?
    end

    users = @course.users
    @students = users.role('student').order(character_sum: :desc).limit(4)
    @volunteers = users.role('online_volunteer') + users.role('campus_volunteer')
    @courses_users = @course.courses_users
    @articles = @course.articles.order(:title).limit(4)

    respond_to do |format|
      format.json { render json: @course }
      format.html { render }
    end
  end

  def recent
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @revisions = @course.revisions.order(date: :desc).limit(20)
  end

  def students
    @course = Course.find_by_slug(params[:id])
    is_instructor = (user_signed_in? && current_user.instructor?(@course))
    unless @course.listed || is_instructor
      fail ActionController::RoutingError 'Not Found' unless @course.nil?
    end

    users = @course.users
    return if users.empty?
    @courses_users = @course.courses_users
                     .includes(user: { assignments: :article })
                     .where(role: 0).order('users.wiki_id')
    @volunteers = users.role('online_volunteer') + users.role('campus_volunteer')
  end

  def articles
    @course = Course.find_by_slug(params[:id])
    is_instructor = (user_signed_in? && current_user.instructor?(@course))
    unless @course.listed || is_instructor
      fail ActionController::RoutingError 'Not Found' unless @course.nil?
    end

    users = @course.users
    @articles_courses = @course.articles_courses.live
                        .includes(:article).order('articles.title')
    @volunteers = users.role('online_volunteer') + users.role('campus_volunteer')
  end

  def manual_update
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @course.manual_update
    redirect_to :back # Refresh if JS blows up
  end
  helper_method :manual_update

  def notify_untrained
    @course = Course.find(params[:course])
    return unless user_signed_in? && current_user.instructor?(@course)
    WikiEdits.notify_untrained(params[:course], current_user)
    redirect_to :back # Refresh if JS blows up
  end
  helper_method :notify_untrained
end
