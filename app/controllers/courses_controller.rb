require 'oauth'
require "#{Rails.root}/lib/wiki_edits"

#= Controller for course functionality
class CoursesController < ApplicationController
  respond_to :html, :json
  before_action :require_permissions, only: [:create, :update, :destroy]

  ###############
  # Root method #
  ###############
  def index
    if user_signed_in?
      @user_courses = current_user.courses.map do |c|
        c if current_user.instructor?(c) || c.listed
      end
    end

    if params.key?(:cohort)
      @cohort = Cohort.includes(:students).find_by(slug: params[:cohort])
    elsif !Figaro.env.default_cohort.nil?
      @cohort = Cohort.includes(:students).find_by(slug: Figaro.env.default_cohort)
    end
    @cohort ||= nil

    raise ActionController::RoutingError.new('Not Found') if @cohort.nil?

    @courses = @cohort.courses.where(listed: true).order(:title)
    @trained = @cohort.students.where(trained: true).count
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
      WikiEdits.update_course(@course, current_user)
      CoursesUsers.create(user: current_user, course: @course, role: 1)
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
    WikiEdits.update_course(@course, current_user)
    respond_to do |format|
      format.json { render json: @course }
    end

  end

  def destroy
    validate
    @course.courses_users.destroy_all
    @course.articles_courses.destroy_all
    @course.assignments.destroy_all
    @course.cohorts_courses.destroy_all
    @course.weeks.destroy_all
    @course.gradeables.destroy_all
    @course.destroy
    WikiEdits.update_course(@course, current_user, true)
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

  def raw
    standard_setup
  end

  def show
    standard_setup
    respond_to do |format|
      format.html { render :overview }
    end
  end

  def check
    course_exists = Course.exists?(slug: params[:id])
    @course = Course.find_by_slug(params[:id]) || {}
    @validation = { course_exists: course_exists, course: @course, params: params }
    respond_to do |format|
      format.json { render json: @validation }
    end
  end

  def overview
    standard_setup
    @courses_users = @course.courses_users
    @articles = @course.articles.order(:title).limit(4)
    ***REMOVED***
    respond_to do |format|
      format.json { render json: @course }
      format.html { render }
    end
  end

  def timeline
    standard_setup
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
    @articles_courses
  end

  def assignments
    standard_setup
  end

  def activity
    standard_setup
    @revisions = @course.revisions.live
                 .includes(:article).includes(:user).order(date: :desc)
  end

  def uploads
    standard_setup
    @uploads = @course.uploads
    @uploads
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
    standard_setup
    WikiEdits.notify_untrained(params[:course], current_user)
    redirect_to show_path(@course)
  end
  helper_method :notify_untrained

  # Will send custom message to course user's talk pages on Wikipedia
  # Responds to route '/notify_students'
  # :roles is optional and will send to specific roles using comma-seperated string 'student,instructor', etc.
  # if :roles is omitted, will send , message to all course users
  # Send the variables via query params, eg. '/courses/*id/notify_students?sectiontitle=TITLE&text=TEXT&summary=SUMMARY&roles=student,instructor'
  # :sectiontitle, :text, :summary, :roles
  # TODO WRITE TEST
  def notify_students
    standard_setup
    recipients = []
    if params[:roles]
      recipient_roles = params[:roles].split(',')
      recipient_roles.each do |role|
        recipients = recipients + @course.users.role(role)
      end
    else
      recipients = @course.users
    end
    if recipients.count > 0
      WikiEdits.notify_students(@course.id, current_user, recipients, params)
    end
    redirect_to show_path(@course)
  end
  helper_method :notify_course_users
end
