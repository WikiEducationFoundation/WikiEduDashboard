# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_cache_manager"

#= Adds a user to a course
class JoinCourse
  attr_reader :result

  # rubocop:disable Metrics/ParameterLists
  def initialize(course:, user:, role:, real_name: nil, role_description: nil, event_sync: false)
    @course = course
    @user = user
    @role = role
    @real_name = real_name
    @role_description = role_description
    @event_sync = event_sync
    process_join_request
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def process_join_request
    validate_request { return }
    create_courses_user
    update_course_user_count
    # This needs to use string keys because it is used in Sidekiq arguments.
    @result = { 'success' => 'User added to course.' }
  end

  def validate_request
    if user_already_enrolled?
      @result = { 'failure' => 'cannot_join_twice' }
    elsif course_withdrawn?
      @result = { 'failure' => 'withdrawn' }
    elsif invalid_sync?
      @result = { 'failure' => 'invalid_sync' }
    elsif student_joining_before_approval?
      @result = { 'failure' => 'not_yet_approved' }
    else
      return
    end
    yield
  end

  # For Wiki Ed courses, a user with any CoursesUsers record for the course is
  # considered to be enrolled already, even if they are not enrolled in the STUDENT role.
  # Instructors should not be enrolled as students.
  # For other course types, enrollment in multiple roles is allowed.
  def user_already_enrolled?
    if @course.multiple_roles_allowed?
      CoursesUsers.exists?(user_id: @user.id, course_id: @course.id, role: @role)
    else
      CoursesUsers.exists?(user_id: @user.id, course_id: @course.id)
    end
  end

  def course_withdrawn?
    @course.withdrawn
  end

  def invalid_sync?
    # If this is an `event_sync` request, the course must
    # have event sync enabled. Otherwise, it must *not* have
    # event sync enabled.
    return false unless student_role? # other roles are not handled by event sync
    @course.controlled_by_event_center? != @event_sync
  end

  def student_joining_before_approval?
    return false unless student_role?
    !@course.approved?
  end

  def student_role?
    @role == CoursesUsers::Roles::STUDENT_ROLE
  end

  def create_courses_user
    CoursesUsers.create(
      user_id: @user.id,
      course_id: @course.id,
      role: @role,
      real_name: @real_name,
      role_description: @role_description
    )
  end

  def update_course_user_count
    # The course user count is the number of students.
    return unless student_role?
    CourseCacheManager.new(@course).update_user_count
    @course.save
  end
end
