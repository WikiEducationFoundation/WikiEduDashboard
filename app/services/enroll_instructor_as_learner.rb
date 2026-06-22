# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_cache_manager"

# Enrolls an instructor as a student of their own course, so that they can
# complete the assignment alongside their students ("learning to edit with your
# students" wizard option). This creates a second CoursesUsers row with the
# student role for a user who is already an instructor.
#
# Unlike a normal student enrollment (JoinCourse), this:
#   - is allowed even before the course is approved, since the instructor is
#     opting in via the wizard at course-creation time, and
#   - does not post enrollment templates to the instructor's userpage/sandbox.
class EnrollInstructorAsLearner
  attr_reader :result

  def initialize(course:, instructor:)
    @course = course
    @instructor = instructor
    enroll
  end

  private

  def enroll
    return @result = { 'failure' => 'withdrawn' } if @course.withdrawn
    return @result = { 'failure' => 'disallowed_user' } if user_disallowed?
    return @result = { 'failure' => 'already_enrolled' } if already_a_learner?
    create_student_courses_user
    CourseCacheManager.new(@course).update_user_count
    @result = { 'success' => 'Instructor enrolled as a student.' }
  end

  def user_disallowed?
    DisallowedUsers.disallowed?(@instructor.username)
  end

  def already_a_learner?
    CoursesUsers.exists?(user_id: @instructor.id, course_id: @course.id,
                         role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  def create_student_courses_user
    CoursesUsers.create(user_id: @instructor.id, course_id: @course.id,
                        role: CoursesUsers::Roles::STUDENT_ROLE)
  end
end
