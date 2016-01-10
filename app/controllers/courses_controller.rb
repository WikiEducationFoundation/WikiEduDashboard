require 'oauth'
require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/wiki_course_edits"

#= Controller for course functionality
class CoursesController < ApplicationController
  include CourseHelper
  respond_to :html, :json
  before_action :require_permissions, only: [:create, :update, :destroy, :notify_untrained]

  ################
  # CRUD methods #
  ################

  def create
    slug_from_params if should_set_slug?
    @course =
      Course.create(course_params.merge('passcode' => Course.generate_passcode))
    handle_timeline_dates
    CoursesUsers.create(user: current_user,
                        course: @course,
                        role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  def update
    validate
    handle_course_announcement(@course.instructors.first)
    slug_from_params if should_set_slug?
    handle_timeline_dates
    @course.update course: course_params
    @course.update_attribute(
      :passcode, Course.generate_passcode
    ) if course_params[:passcode].nil?

    WikiCourseEdits.new(action: :update_course,
                        course: @course,
                        current_user: current_user)
    render json: { course: @course }
  end

  def destroy
    validate
    @course.destroy
    WikiCourseEdits.new(action: :update_course,
                        course: @course,
                        current_user: current_user,
                        delete: true)
    render json: { success: true }
  end

  ########################
  # View support methods #
  ########################

  def show
    @course = find_course_by_slug("#{params[:school]}/#{params[:titleterm]}")
    check_permission_to_show_course

    # If the user could make an edit to the course, then verify that
    # their tokens are working.
    if current_user && current_user.can_edit?(@course)
      unless WikiEdits.oauth_credentials_valid?(current_user)
        redirect_to root_path
        return
      end
    end

    respond_to do |format|
      format.html { render }
      format.json { render params[:endpoint] }
    end
  end

  def clone
    course = Course.find(params[:id])
    new_course = CourseCloneManager.new(course, current_user).clone!
    render json: { course: new_course.as_json }
  end

  ##################
  # Helper methods #
  ##################

  def check
    course_exists = Course.exists?(slug: params[:id])
    render json: { course_exists: course_exists }
  end

  def check_permission_to_show_course
    # A user may not see an existing course if it has been de-listed, unless
    # that user in the instructor.
    return if @course.nil?
    return if @course.listed?
    is_instructor = (user_signed_in? && current_user.instructor?(@course))
    return if is_instructor

    fail ActionController::RoutingError
      .new('Not Found'), 'Not permitted'
  end

  # JSON method for listing/unlisting course
  def list
    @course = find_course_by_slug(params[:id])
    cohort = Cohort.find_by(title: cohort_params[:title])
    unless cohort
      render json: {
        message: "Sorry, #{cohort_params[:title]} is not a valid cohort."
      }, status: 404
      return
    end
    ListCourseManager.new(@course, cohort, request).manage
  end

  def tag
    @course = find_course_by_slug(params[:id])
    TagManager.new(@course, request).manage
  end

  def manual_update
    @course = find_course_by_slug(params[:id])
    @course.manual_update if user_signed_in?
    render nothing: true, status: :ok
  end
  helper_method :manual_update

  def notify_untrained
    @course = find_course_by_slug(params[:id])
    WikiEdits.notify_untrained(@course.id, current_user)
    render nothing: true, status: :ok
  end
  helper_method :notify_untrained

  private

  def cohort_params
    params.require(:cohort).permit(:title)
  end

  def validate
    slug = params[:id].gsub(/\.json$/, '')
    @course = find_course_by_slug(slug)
    return unless user_signed_in? && current_user.instructor?(@course)
  end

  def handle_timeline_dates
    @course.timeline_start = @course.start if @course.timeline_start.nil?
    @course.timeline_end = @course.end if @course.timeline_end.nil?
    @course.save
  end

  def handle_course_announcement(instructor)
    newly_submitted = !@course.submitted? && course_params[:submitted] == true
    return unless newly_submitted
    WikiCourseEdits.new(action: 'announce_course',
                        course: @course,
                        current_user: current_user,
                        instructor: instructor)
  end

  def should_set_slug?
    %i(title school term).all? { |key| params[:course].key?(key) }
  end

  def slug_from_params(course = params[:course])
    course[:slug] = "#{course[:school]}/#{course[:title]}_(#{course[:term]})"
                    .tr(' ', '_')
  end

  def course_params
    params
      .require(:course)
      .permit(:id, :title, :description, :school, :term, :slug, :subject,
              :expected_students, :start, :end, :submitted, :listed, :passcode,
              :timeline_start, :timeline_end, :day_exceptions, :weekdays,
              :no_day_exceptions, :cloned_status)
  end
end
