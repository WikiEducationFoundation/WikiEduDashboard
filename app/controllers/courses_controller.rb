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
      if current_user.permissions > 0
        @admin_courses = Course.includes(:cohorts).where('cohorts.id IS NULL')
                         .where(listed: true).where(submitted: true)
                         .references(:cohorts)
      end

      @user_courses = current_user.courses.current_and_future.select do |c|
        c if c.listed
      end
    end

    if params.key?(:cohort)
      if params[:cohort] == 'none'
        @cohort = OpenStruct.new(
          title: 'Unsubmitted Courses',
          slug: 'none',
          students: []
        )
        @courses = Course.where(submitted: false)
                   .where(listed: true).where('id >= 10000')
        return
      else
        @cohort = Cohort.includes(:students).find_by(slug: params[:cohort])
      end
    elsif !Figaro.env.default_cohort.nil?
      slug = Figaro.env.default_cohort
      @cohort = Cohort.includes(:students).find_by(slug: slug)
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

    unless params[:course].key? :timeline_start
      params[:course][:timeline_start] = params[:course][:start]
    end

    params[:course][:passcode] = ('a'..'z').to_a.shuffle[0, 8].join

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
      :end,
      :submitted,
      :listed,
      :passcode,
      :timeline_start
    )
  end

  def create
    if Course.exists?(slug: course_params[:slug])
      flash[:notice] = t('course.error.exists')
      redirect_to :back
    else
      @course = Course.create(course_params)
      CoursesUsers.create(user: current_user, course: @course, role: 1)
    end
  end

  def validate
    slug = params[:id].gsub(/\.json$/, '')
    @course = find_course_by_slug(slug)
    return unless user_signed_in? && current_user.instructor?(@course)
  end

  def update
    validate
    params = {}
    params['course'] = course_params

    if !(@course.submitted == 1) && params['course']['submitted']
      instructor = @course.instructors.first
      WikiEdits.announce_course(@course, current_user, instructor)
    end

    @course.update params
    WikiEdits.update_course(@course, current_user)
    respond_to do |format|
      format.json { render json: @course }
    end
  end

  def destroy
    validate
    WikiEdits.update_assignments current_user, @course, nil, true
    @course.courses_users.destroy_all
    @course.articles_courses.destroy_all
    @course.assignments.destroy_all
    @course.cohorts_courses.destroy_all
    @course.weeks.destroy_all
    @course.gradeables.destroy_all
    @course.destroy
    WikiEdits.update_course(@course, current_user, true)
    respond_to do |format|
      format.json { render json: { success: true } }
    end
  end

  ########################
  # View support methods #
  ########################
  def find_course_by_slug(slug)
    course = Course.where(listed: true).find_by_slug(slug)
    if course.nil?
      fail ActionController::RoutingError.new('Not Found'), 'Course not found'
    end
    return course
  end

  def volunteers
    return nil if @course.nil?
    users = @course.users
    users.role('online_volunteer') + users.role('campus_volunteer')
  end

  def get_wiki_top_section
    @course = find_course_by_slug(params[:id])
    response = WikiEdits.get_wiki_top_section(@course.slug, current_user)
    respond_to do |format|
      format.json { render json: response }
    end
  end

  def show
    @course = find_course_by_slug("#{params[:school]}/#{params[:titleterm]}")

    is_instructor = (user_signed_in? && current_user.instructor?(@course))
    if @course.nil? || @course.listed || is_instructor
      respond_to do |format|
        format.html { render }
        format.json { render params[:endpoint] }
      end
    else
      fail ActionController::RoutingError.new('Not Found'), 'Not permitted'
    end
  end

  def standard_setup
    @course = find_course_by_slug(params[:id])
    @volunteers = volunteers
    is_instructor = (user_signed_in? && current_user.instructor?(@course))
    return if @course.nil? || @course.listed || is_instructor
    fail ActionController::RoutingError.new('Not Found'), 'Not permitted'
  end

  def raw
    standard_setup
  end

  ##################
  # Helper methods #
  ##################
  def check
    course_exists = Course.exists?(slug: params[:id])
    respond_to do |format|
      format.json { render json: { course_exists: course_exists } }
    end
  end

  def cohort_params
    params.require(:cohort).permit(:title)
  end

  def list
    @course = find_course_by_slug(params[:id])
    @cohort = Cohort.find_by(title: cohort_params[:title])
    unless @cohort.nil?
      exists = CohortsCourses.exists?(course_id: @course.id, cohort_id: @cohort.id)
      if request.post? && !exists
        CohortsCourses.create(
          course_id: @course.id,
          cohort_id: @cohort.id
        )
      elsif request.delete?
        CohortsCourses.find_by(
          course_id: @course.id,
          cohort_id: @cohort.id
        ).destroy
      end
    else
      render json: { message: "Sorry, #{cohort_params[:title]} is not a valid cohort." }, status: 404
    end
  end

  def manual_update
    @course = find_course_by_slug(params[:id])
    @course.manual_update if user_signed_in?
    render nothing: true, status: :ok
  end
  helper_method :manual_update

  def notify_untrained
    standard_setup
    WikiEdits.notify_untrained(@course.id, current_user)
    render nothing: true, status: :ok
  end
  helper_method :notify_untrained
end
