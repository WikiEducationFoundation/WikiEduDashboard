# frozen_string_literal: true
class CourseStudents
  def initialize(course)
    @course = course
  end

  def getstudent_names
    student_name = []
    # Retrieve all courses_users with student role
    courses_users.each do |courses_user|
      # Build a string in the format "User:<username>" for each student
      student_name << "User:#{courses_user.user.username}"
    end
    student_name
  end

  private

  # Retrieve student courses_users with associated users
  def courses_users
    @course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE).includes(:user)
  end
end
