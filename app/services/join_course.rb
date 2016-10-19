# frozen_string_literal: true
require "#{Rails.root}/lib/course_cache_manager"

#= Adds a user to a course
class JoinCourse
  attr_reader :result

  def initialize(course:, user:, role:)
    @course = course
    @user = user
    @role = role
    process_join_request
  end

  private

  def process_join_request
    validate_request { return }
    create_courses_user
    update_course_user_count
    @result = { success: 'User added to course.' }
  end

  def validate_request
    return unless user_already_enrolled? || course_not_approved?
    @result = { failure: 'Users may not join the same course twice.' }
    yield
  end

  # A user with any CoursesUsers record for the course is considered to be
  # enrolled already, even if they are not enrolled in the STUDENT role.
  # Instructors should not be enrolled as students.
  def user_already_enrolled?
    CoursesUsers.exists?(user_id: @user.id,
                         course_id: @course.id)
  end

  def course_not_approved?
    @course.cohorts.empty?
  end

  def create_courses_user
    CoursesUsers.create(
      user_id: @user.id,
      course_id: @course.id,
      role: @role
    )
  end

  def update_course_user_count
    # The course user count is the number of students.
    return unless @role == CoursesUsers::Roles::STUDENT_ROLE
    CourseCacheManager.new(@course).update_user_count
    @course.save
  end
end
