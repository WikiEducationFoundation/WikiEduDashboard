# frozen_string_literal: true

require "#{Rails.root}/app/workers/update_course_worker"
require "#{Rails.root}/app/workers/enroll_in_course_worker"
require "#{Rails.root}/app/workers/set_preferences_worker"

#= Controller for students enrolling in courses
class SelfEnrollmentController < ApplicationController
  respond_to :html, :json

  def enroll_self
    # Catch HEAD requests
    respond_to_non_get_request { return }

    set_course
    # Don't allow users to self-enroll if the course has already ended.
    redirect_if_course_ended { return }

    # Redirect to sign in (with callback leading back to this method)
    redirect_if_user_logged_out { return }

    redirect_if_passcode_invalid { return }

    # Creates the CoursesUsers record
    add_student_to_course

    # Make sure the user isn't already enrolled.
    redirect_if_enrollment_failed { return }

    # Set email and VE preferences
    set_mediawiki_preferences if Features.wiki_ed?
    # Automatic edits for newly enrolled user
    make_enrollment_edits

    redirect_to course_slug_path(@course.slug, enrolled: true)
  end

  private

  def respond_to_non_get_request
    return if request.get?
    render json: { status: 200 }
    yield
  end

  def set_course
    @course = Course.find_by_slug(params[:course_id])
    # Check if the course exists
    raise ActionController::RoutingError, 'Course not found' if @course.nil?
  end

  def redirect_if_course_ended
    return unless course_ended?
    flash[:notice] = 'You cannot join this course. It has already ended.'
    redirect_to course_slug_path(@course.slug)
    yield
  end

  def course_ended?
    @course.end < Time.zone.now
  end

  def redirect_if_user_logged_out
    return unless current_user.nil?
    auth_path = user_mediawiki_omniauth_authorize_path
    path = "#{auth_path}?origin=#{request.original_url}"
    redirect_to path
    yield
  end

  def redirect_if_enrollment_failed
    return unless @result[:failure]
    redirect_to course_slug_path(@course.slug, enrolled: false, failure_reason: @result[:failure])
    yield
  end

  def redirect_if_passcode_invalid
    return if passcode_valid?
    redirect_to '/errors/incorrect_passcode'
    yield
  end

  def passcode_valid?
    # If course has no passcode set, treat any submission as valid.
    return true if @course.passcode.blank?
    params[:passcode] == @course.passcode
  end

  def add_student_to_course
    @result = JoinCourse.new(course: @course,
                             user: current_user,
                             role: CoursesUsers::Roles::STUDENT_ROLE,
                             real_name: current_user.real_name).result
  end

  def set_mediawiki_preferences
    SetPreferencesWorker.schedule_preference_setting(user: current_user)
  end

  def make_enrollment_edits
    # Posts templates to userpage and sandbox and
    # adds user to course page by updating course page with latest course info
    EnrollInCourseWorker.schedule_edits(course: @course,
                                        editing_user: current_user,
                                        enrolling_user: current_user)
  end
end
