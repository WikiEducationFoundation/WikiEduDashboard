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

    # Redirect to sign in (with callback leading back to this method)
    if current_user.nil?
      handle_logged_out_user
      return
    end

    # Make sure the user isn't already enrolled.
    if user_already_enrolled?
      redirect_to course_slug_path(@course.slug)
      return
    end

    # Check passcode, enroll if valid
    if passcode_valid?
      add_student_to_course
      WikiEdits.enroll_in_course(@course, current_user)
      WikiEdits.update_course(@course, current_user)
    end

    redirect_to course_slug_path(@course.slug, enrolled: true)
  end

  private

  def set_course
    @course = Course.find_by_slug(params[:course_id])
    # Check if the course exists
    fail ActionController::RoutingError, 'Course not found' if @course.nil?
  end

  def handle_logged_out_user
    auth_path = user_omniauth_authorize_path(:mediawiki)
    path = "#{auth_path}?origin=#{request.original_url}"
    redirect_to path
  end

  def user_already_enrolled?
    CoursesUsers.exists?(user_id: current_user.id,
                         course_id: @course.id,
                         role: CoursesUsers::Roles::STUDENT_ROLE)
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
end
