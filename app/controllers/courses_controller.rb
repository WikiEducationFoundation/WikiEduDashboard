require 'oauth'
require "#{Rails.root}/lib/wiki_edits"

#= Controller for course functionality
class CoursesController < ApplicationController
  include CourseHelper
  respond_to :html, :json
  before_action :require_permissions, only: [:create, :update, :destroy]

  ###############
  # Root method #
  ###############
  def index
    if user_signed_in?
      @admin_courses = Course.submitted_listed if current_user.admin?
      @user_courses = current_user.courses.current_and_future.select(&:listed)
    end

    return handle_no_cohort if params[:cohort] == 'none'

    @cohort = set_cohort(params)
    @courses = @cohort.courses.listed.order(:title)
  end

  ################
  # CRUD methods #
  ################

  def create
    handle_instructor_info if should_update_instructor_info?
    set_slug if should_set_slug?
    @course = Course.create(course_params.merge('passcode' => Course.generate_passcode))
    handle_timeline_dates
    CoursesUsers.create(user: current_user, course: @course, role: 1)
  end

  def update
    validate
    newly_submitted = !@course.submitted? && course_params[:submitted] == true
    announce_course(@course.instructors.first) if newly_submitted
    handle_instructor_info if should_update_instructor_info?
    handle_timeline_dates
    @course.update course: course_params
    @course.update_attribute(:passcode, Course.generate_passcode) if course_params[:passcode].nil?

    WikiEdits.update_course(@course, current_user)
    render json: @course
  end

  def destroy
    validate
    @course.destroy
    WikiEdits.update_assignments current_user, @course, nil, true
    WikiEdits.update_course(@course, current_user, true)
    render json: { success: true }
  end

  ########################
  # View support methods #
  ########################

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

  ##################
  # Helper methods #
  ##################

  def check
    course_exists = Course.exists?(slug: params[:id])
    render json: { course_exists: course_exists }
  end

  def list
    @course = find_course_by_slug(params[:id])
    @cohort = Cohort.find_by(title: cohort_params[:title])
    if @cohort.nil?
      render json: { message: "Sorry, #{cohort_params[:title]} is not a valid cohort." }, status: 404 and return
    end
    if request.post?
      return if CohortsCourses.find_by(course_id: @course.id, cohort_id: @cohort.id).present?
      CohortsCourses.create(course_id: @course.id, cohort_id: @cohort.id)
    elsif request.delete?
      CohortsCourses.find_by(course_id: @course.id, cohort_id: @cohort.id).destroy
    end
  end

  def tag
    @course = find_course_by_slug(params[:id])
    t_params = { course_id: @course.id, tag: tag_params[:tag] }
    if request.post?
      return if Tag.find_by(t_params).present?
      Tag.create(t_params)
    elsif request.delete?
      return unless Tag.find_by(t_params).present?
      Tag.find_by(t_params).destroy
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

  private

  def tag_params
    params.require(:tag).permit(:tag)
  end

  def cohort_params
    params.require(:cohort).permit(:title)
  end

  def validate
    slug = params[:id].gsub(/\.json$/, '')
    @course = find_course_by_slug(slug)
    return unless user_signed_in? && current_user.instructor?(@course)
  end

  def should_update_instructor_info?
    (%w(instructor_email instructor_name) & params[:course].keys).any?
  end

  def handle_instructor_info
    c_params = params[:course]
    current_user.real_name = c_params['instructor_name'] if c_params.key?('instructor_name')
    current_user.email = c_params['instructor_email'] if c_params.key?('instructor_email')
    current_user.save
    c_params.delete('instructor_email')
    c_params.delete('instructor_name')
  end

  def handle_timeline_dates
    @course.timeline_start = @course.start if @course.timeline_start.nil?
    @course.timeline_end = @course.end if @course.timeline_end.nil?
    @course.save
  end

  def announce_course(instructor)
    WikiEdits.announce_course(@course, current_user, instructor)
  end

  def standard_setup
    @course = find_course_by_slug(params[:id])
    return unless @course
    @volunteers = @course.volunteers
    return if @course.listed || (current_user && current_user.instructor?)
    fail ActionController::RoutingError.new('Not Found'), 'Not permitted'
  end

  def unsubmitted_cohort
    OpenStruct.new(
      title: 'Unsubmitted Courses',
      slug: 'none',
      students_without_instructor_students: [],
      trained_count: 0
    )
  end

  def handle_no_cohort
    @cohort = unsubmitted_cohort
    @courses = Course.unsubmitted_listed
  end

  def set_cohort(params)
    default_cohort = Figaro.env.default_cohort || ENV['default_cohort']
    if params[:cohort] && !Cohort.exists?(slug: params[:cohort]) 
      raise ActionController::RoutingError.new('Cohort must be selected or set by default')
    end
    Cohort.includes(:students).find_by(slug: (params[:cohort] || default_cohort))
  end

  def should_set_slug?
    %i(title school term).all? { |key| params[:course].key?(key) }
  end

  def set_slug
    course = params[:course]
    course[:slug] = "#{course[:school]}/#{course[:title]}_(#{course[:term]})".gsub(' ', '_')
  end

  def course_params
    params.require(:course).permit(:id, :title, :description, :school, :term,
      :slug, :subject, :expected_students, :start, :end, :submitted, :listed,
      :passcode, :timeline_start, :timeline_end, :day_exceptions, :weekdays,
      :no_day_exceptions)
  end
end
