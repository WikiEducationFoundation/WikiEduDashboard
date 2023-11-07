# frozen_string_literal: true

require_dependency Rails.root.join('lib/wiki_course_edits')
require_dependency Rails.root.join('app/workers/update_course_worker')
require_dependency Rails.root.join('lib/importers/user_importer')

class Users::EnrollmentController < ApplicationController
  respond_to :html, :json
  before_action :require_participating_user, only: [:index]
  def index
    if request.post?
      add
    elsif request.delete?
      remove
    end
  end

  private

  #################
  # Adding a user #
  #################
  def add
    set_course_and_user
    ensure_user_exists { return }
    set_real_name
    @result = JoinCourse.new(course: @course,
                             user: @user,
                             role: enroll_params[:role],
                             role_description: enroll_params[:role_description],
                             real_name: @real_name).result
    ensure_enrollment_success { return }

    alert_staff_if_new_instructor_was_added
    update_course_page_and_assignment_talk_templates
    make_enrollment_edits
    render 'users', formats: :json
  end

  def ensure_user_exists
    return unless @user.nil?
    username = enroll_params[:user_id] || enroll_params[:username]
    domain = @course.home_wiki.domain
    message = I18n.t('courses.error.user_exists_on_wiki', username:, domain:)
    render json: { message: },
           status: :not_found
    yield
  end

  # Users may have their real name set, if they went through /onboarding.
  # However, these real names are not public information; they are used primarily
  # so that people in a class together can see both names and usernames.
  # This method sets the real name that is associated with the CoursesUsers
  # enrollment record, but only if the adding user is allowed to know it.
  def set_real_name
    @real_name = enroll_params[:real_name]
    # On P&E Dashboard, real name is not set except via self-enrollment
    # or via explicitly submitted params.
    return unless Features.wiki_ed?
    # On Wiki Education Dashboard, if the course is approved, we allow the
    # instructors to add users and still include the real name.
    return unless adding_self? || current_user.admin? || @course.approved?

    @real_name ||= @user.real_name
  end

  def adding_self?
    current_user.id == @user.id
  end

  def ensure_enrollment_success
    return unless @result['failure']
    message = I18n.t("courses.join_failure_details.#{@result['failure']}")
    render json: { message: }, status: :not_found
    yield
  end

  def make_enrollment_edits
    return unless student_role?
    # for students only, posts templates to userpage and sandbox
    EnrollInCourseWorker.schedule_edits(course: @course,
                                        editing_user: current_user,
                                        enrolling_user: @user)
  end

  def alert_staff_if_new_instructor_was_added
    return unless instructor_role?
    NewInstructorEnrollmentMailer.send_staff_alert(adder: current_user,
                                                   new_instructor: @user,
                                                   course: @course)
  end

  def instructor_role?
    enroll_params[:role].to_i == CoursesUsers::Roles::INSTRUCTOR_ROLE
  end

  def student_role?
    enroll_params[:role].to_i == CoursesUsers::Roles::STUDENT_ROLE
  end

  ###################
  # Removing a user #
  ###################
  def remove
    set_course_and_user
    return if @user.nil?

    ensure_role_is_authorized { return }
    ensure_course_user_exists { return }

    remove_assignment_templates
    make_disenrollment_edits

    @course_user.destroy # destroying the course_user also destroys associated Assignments.

    render 'users', formats: :json
    update_course_page_and_assignment_talk_templates
  end

  # For events controlled by Event Center, only non-student roles
  # can be changed on the Dashboard. Student role is handled
  # via WikimediaEventCenterController.
  def ensure_role_is_authorized
    return unless @course.controlled_by_event_center? && student_role?
    render json: { message: I18n.t('courses.controlled_by_event_center') }, status: :unauthorized
    yield
  end

  def ensure_course_user_exists
    @course_user = CoursesUsers.find_by(user: @user, course: @course,
                                        role: enroll_params[:role])
    return unless  @course_user.nil? # This will happen if the user was already removed.
    render 'users', formats: :json
    yield
  end

  # If the user has Assignments, update article talk pages to remove them from
  # the assignment templates.
  def remove_assignment_templates
    assignments = @course_user.assignments
    assignments.each do |assignment|
      WikiCourseEdits.new(action: :remove_assignment, course: @course,
                          current_user:, assignment:)
    end
  end

  # Remove enrollment templates from user page and user talk page.
  def make_disenrollment_edits
    return unless student_role?
    # for students only, remove templates from userpage and user talk page
    DisenrollFromCourseWorker.schedule_edits(course: @course,
                                             editing_user: current_user,
                                             disenrolling_user: @user)
  end

  ##################
  # Finding a user #
  ##################
  def set_course_and_user
    @course = Course.find_by(slug: params[:id])
    if enroll_params.key? :user_id
      @user = User.find(enroll_params[:user_id])
    elsif enroll_params.key? :username
      find_or_import_user_by_username
    end
  end

  def find_or_import_user_by_username
    username = enroll_params[:username]
    @user = User.find_by(username:)
    @user = UserImporter.new_from_username(username, @course.home_wiki) if @user.nil?
  end

  def enroll_params
    params.require(:user).permit(:user_id, :username, :role, :real_name, :role_description)
  end

  ##################
  # Helper methods #
  ##################
  def update_course_page_and_assignment_talk_templates
    UpdateCourseWorker.schedule_edits(course: @course, editing_user: current_user)
  end
end
