require 'oauth'
require "#{Rails.root}/lib/wiki_edits"

#= Controller for course functionality
class CoursesController < ApplicationController
  respond_to :html, :json

  ###############
  # Root method #
  ###############
  def index
    @cohort = params[:cohort].present? ? params[:cohort] : 'spring_2015'

    if user_signed_in?
      @user_courses = current_user.courses.map do |c|
        c if current_user.instructor?(c) || c.listed
      end
    end

    @cohort = Cohort.find_by(slug: @cohort)
    raise ActionController::RoutingError.new('Not Found') if @cohort.nil?

    @courses = @cohort.courses.where(listed: true).order(:title)
    @untrained = @courses.sum(:untrained_count)
    @trained = @courses.sum(:user_count) - @courses.sum(:untrained_count)
  end

  ################
  # CRUD methods #
  ################
  def course_params
    slugify = params[:course].key? :title
    slugify &= params[:course].key? :school
    slugify &= params[:course].key? :term

    if slugify
      title = params[:course][:title].gsub(' ', '_')
      school = params[:course][:school].gsub(' ', '_')
      term = params[:course][:term].gsub(' ', '_')
      params[:course][:slug] = "#{school}/#{title}_(#{term})"
    end

    params.require(:course).permit(
      :id,
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

  def validate
    @course = Course.find_by_slug(params[:id])
    return unless user_signed_in? && current_user.instructor?(@course)
  end

  def update
    validate
    params = {}
    params['course'] = course_params
    @course.update params
    respond_to do |format|
      format.json { render json: @course }
    end
  end

  def destroy
    validate
    @course.destroy
    redirect_to :root
  end

  ########################
  # View support methods #
  ########################
  def volunteers
    return nil if @course.nil?
    users = @course.users
    users.role('online_volunteer') + users.role('campus_volunteer')
  end

  def standard_setup
    @course = Course.find_by_slug(params[:id])
    @volunteers = volunteers
    is_instructor = (user_signed_in? && current_user.instructor?(@course))
    return if @course.listed || is_instructor || @course.nil?
    fail ActionController::RoutingError.new('Not Found'), 'Not permitted'
  end

  def show
    standard_setup
    respond_to do |format|
      format.json { render json: @course }
      format.html { redirect_to :overview }
    end
  end

  def overview
    standard_setup
    @courses_users = @course.courses_users
    @articles = @course.articles.order(:title).limit(4)
    respond_to do |format|
      format.json { render json: @course }
      format.html { render }
    end
  end

  def timeline
    standard_setup
    respond_to do |format|
      format.json do
        render json: @course.as_json(
          include: { weeks: {
            include: { blocks: { include: :gradeable } }
          } }
        )
      end
      format.html { render }
    end
  end

  def students
    standard_setup
    return if @course.users.empty?
    @courses_users = @course.courses_users
                     .includes(user: { assignments: :article })
                     .where(role: 0).order('users.wiki_id')
  end

  def articles
    standard_setup
    @articles_courses = @course.articles_courses.live
                        .includes(:article).order('articles.title')
  end

  ##################
  # Helper methods #
  ##################
  def manual_update
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @course.manual_update if user_signed_in?
    redirect_to show_path(@course)
  end
  helper_method :manual_update

  def notify_untrained
    @course = Course.find(params[:course])
    return unless user_signed_in? && current_user.instructor?(@course)
    WikiEdits.notify_untrained(params[:course], current_user)
    redirect_to show_path(@course)
  end
  helper_method :notify_untrained
end
