require "#{Rails.root}/lib/wiki_course_edits"

#= Controller for user functionality
class UsersController < ApplicationController
  respond_to :html, :json
  before_action :require_participating_user,
                only: [:save_assignments, :enroll]

  def signout
    if current_user.nil?
      redirect_to '/'
    else
      current_user.update_attributes(wiki_token: nil, wiki_secret: nil)
      redirect_to true_destroy_user_session_path
    end
  end

  # Onboarding sets the user's real name, email address, and optionally instructor permissions
  def onboard
    [:real_name, :email, :instructor].each_with_object(params) do |key, obj|
      obj.require(key)
    end

    user = User.find(current_user.id)

    permissions = user.permissions
    if params[:instructor] == true
      permissions = User::Permissions::INSTRUCTOR unless permissions == User::Permissions::ADMIN
    end

    user.update_attributes(real_name: params[:real_name],
                           email: params[:email],
                           permissions: permissions,
                           onboarded: true)

    render nothing: true, status: 204
  end

  #########################
  # Enrollment management #
  #########################
  def enroll
    if request.post?
      add
    elsif request.delete?
      remove
    end
  end

  private

  def add
    fetch_enroll_records
    if !@user.nil?
      # Instructors and others with non-student roles may not enroll as students
      if @user.can_edit?(@course) && enroll_params[:role].to_i == CoursesUsers::Roles::STUDENT_ROLE
        render json: { message: 'Instructors and volunteers cannot enroll as students.' },
               status: 404
        return
      end

      CoursesUsers.create(
        user: @user,
        course_id: @course.id,
        role: enroll_params[:role]
      )

      WikiCourseEdits.new(action: :update_course, course: @course, current_user: current_user)
      render 'users', formats: :json
    else
      username = enroll_params[:user_id] || enroll_params[:username]
      render json: I18n.t('courses.error.user_exists',username: username),
             status: 404
    end
  end

  def remove
    fetch_enroll_records
    return if @user.nil?

    course_user = CoursesUsers.find_by(
      user_id: @user.id,
      course_id: @course.id,
      role: enroll_params[:role]
    )
    return if course_user.nil? # This will happen if the user was already removed.
    assignments = course_user.assignments
    assignments.each do |assignment|
      WikiCourseEdits.new(action: :remove_assignment,
                          course: @course,
                          current_user: current_user,
                          assignment: assignment)
    end

    course_user.destroy # destroying the course_user also destroys associated Assignments.
    render 'users', formats: :json
    WikiCourseEdits.new(action: :update_course, course: @course, current_user: current_user)
  end

  def fetch_enroll_records
    require "#{Rails.root}/lib/importers/user_importer"

    @course = Course.find_by_slug(params[:id])
    if enroll_params.key? :user_id
      @user = User.find(enroll_params[:user_id])
    elsif enroll_params.key? :username
      username = enroll_params[:username]
      @user = User.find_by(username: username)
      @user = UserImporter.new_from_username(username) if @user.nil?
    end
  end

  def enroll_params
    params.require(:user).permit(:user_id, :username, :role)
  end
end
