require "#{Rails.root}/lib/wiki_edits"

#= Controller for students enrolling in courses
class SelfEnrollmentController < ApplicationController
  respond_to :html, :json

  def enroll_self
    # Catch HEAD requests
    unless request.get?
      render json: { status: 200 }
      return
    end

    set_course

    # Don't allow users to self-enroll if the course has already ended.
    if course_ended?
      redirect_to course_slug_path(@course.slug)
      return
    end

    # Redirect to sign in (with callback leading back to this method)
    if current_user.nil?
      handle_logged_out_user
      return
    end

    # Make sure the user isn't already enrolled.
    if user_already_enrolled?
      redirect_to course_slug_path(@course.slug, enrolled: true)
      return
    end

    # Check passcode, enroll if valid
    if passcode_valid?
      # Creates the CoursesUsers record
      add_student_to_course
      # Automatic edits for newly enrolled user
      make_enrollment_edits
      redirect_to course_slug_path(@course.slug, enrolled: true)
    else
      redirect_to '/errors/incorrect_passcode'
    end
  end

  private

  def set_course
    @course = Course.find_by_slug(params[:course_id])
    # Check if the course exists
    raise ActionController::RoutingError, 'Course not found' if @course.nil?
  end

  def course_ended?
    @course.end < Time.zone.now
  end

  def handle_logged_out_user
    auth_path = user_omniauth_authorize_path(:mediawiki)
    path = "#{auth_path}?origin=#{request.original_url}"
    redirect_to path
  end

  # A user with any CoursesUsers record for the course is considered to be
  # enrolled already, even if they are not enrolled in the STUDENT role.
  # Instructors should not be enrolled as students.
  def user_already_enrolled?
    CoursesUsers.exists?(user_id: current_user.id,
                         course_id: @course.id)
  end

  def passcode_valid?
    !@course.passcode.nil? && params[:passcode] == @course.passcode
  end

  def add_student_to_course
    CoursesUsers.create(
      user_id: current_user.id,
      course_id: @course.id,
      role: CoursesUsers::Roles::STUDENT_ROLE
    )
  end

  def make_enrollment_edits
    # Posts templates to userpage and sandbox
    WikiCourseEdits.new(action: :enroll_in_course,
                        course: @course,
                        current_user: current_user)
    # Adds user to course page by updating course page with latest course info
    WikiCourseEdits.new(action: :update_course,
                        course: @course,
                        current_user: current_user)
  end
end
