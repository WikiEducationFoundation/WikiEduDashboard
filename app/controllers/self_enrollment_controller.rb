# frozen_string_literal: true

#= Controller for editors enrolling in courses
class SelfEnrollmentController < ApplicationController
  respond_to :html, :json

  def enroll_self
    # Catch HEAD requests
    respond_to_non_get_request { return }

    # The direct enrollment link only works if you are signed in.
    # The frontend ?enroll= links handle UI for making sure you're signed in
    # before redirecting here.
    require_signed_in

    set_course
    # Don't allow users to self-enroll if the course has already ended.
    redirect_if_course_ended { return }

    redirect_if_passcode_invalid { return }

    # Creates the CoursesUsers record
    add_user_to_course
    # Make sure the user isn't already enrolled.
    redirect_if_enrollment_failed { return }

    # Automatic edits for newly enrolled user
    make_enrollment_edits

    # Alert Wiki Expert if students join a ClassroomProgramCourse before its start date.
    check_early_student_join

    respond_to do |format|
      format.html { redirect_to course_slug_path(@course.slug, enrolled: true) }
      format.json do
        message = I18n.t('courses.join_successful', title: @course.title)
        render json: { message: }, status: :ok
      end
    end
  end

  private

  def check_early_student_join
    return unless @course.is_a?(ClassroomProgramCourse) && @course.start.to_date > Time.zone.today
    return if Alert.exists?(course_id: @course.course_id, type: 'WikiExpertNotificationAlert')

    WikiExpertNotificationAlert.new(course: @course)&.send_email
  end

  def respond_to_non_get_request
    return if request.get?
    render json: { status: 200 }
    yield
  end

  def set_course
    @course = Course.find_by(slug: params[:course_id])
    # Check if the course exists
    raise ActionController::RoutingError, 'Course not found' if @course.nil?
  end

  def redirect_if_course_ended
    return unless course_ended?
    message = 'You cannot join this course. It has already ended.'
    respond_to do |format|
      format.html do
        flash[:notice] = message
        redirect_to course_slug_path(@course.slug)
      end
      format.json do
        render json: { message: }, status: :bad_request
      end
    end

    yield
  end

  def course_ended?
    @course.end < Time.zone.now
  end

  def redirect_if_enrollment_failed
    return unless @result['failure']
    respond_to do |format|
      format.html do
        redirect_to course_slug_path(@course.slug,
                                     enrolled: false,
                                     failure_reason: @result['failure'])
      end
      format.json do
        render json: {
          message: I18n.t("courses.join_failure_details.#{@result['failure']}")
        },
               status: :bad_request
      end
    end
    yield
  end

  def redirect_if_passcode_invalid
    # Passcode is not required for the Online Volunteer role
    return if role == CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE
    return if passcode_valid?
    respond_to do |format|
      format.html do
        path = course_slug_path(@course.slug)
        redirect_to "/errors/incorrect_passcode?retry=#{path}"
      end
      format.json { redirect_to '/errors/incorrect_passcode.json' }
    end

    yield
  end

  def passcode_valid?
    # If course has no passcode set, treat any submission as valid.
    return true if @course.passcode.blank?
    params[:passcode] == @course.passcode
  end

  def role
    if params[:role] == 'online_volunteer'
      CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE
    else
      CoursesUsers::Roles::STUDENT_ROLE
    end
  end

  def add_user_to_course
    @result = JoinCourse.new(course: @course,
                             user: current_user,
                             role:,
                             real_name: current_user.real_name).result
  end

  def make_enrollment_edits
    # Posts templates to userpage and sandbox and
    # adds user to course page by updating course page with latest course info.
    # For Wiki Ed users, also sets their email and VE preferences.
    set_mediawiki_preferences = Features.wiki_ed?
    EnrollInCourseWorker.schedule_edits(course: @course,
                                        editing_user: current_user,
                                        enrolling_user: current_user,
                                        set_wiki_preferences: set_mediawiki_preferences)
  end
end
