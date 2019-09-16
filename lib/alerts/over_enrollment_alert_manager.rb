# frozen_string_literal: true

class OverEnrollmentAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next unless course.type == 'ClassroomProgramCourse'
      next unless over_enrolled?(course)
      next if Alert.exists?(course: course, type: 'OverEnrollmentAlert', resolved: false)

      alert = Alert.create(type: 'OverEnrollmentAlert', course: course)
      alert.email_course_admins
    end
  end

  private

  # Wiki Education has a maximum course size we will support.
  # We also generate alerts if a course has significant more students than expected.
  MAX_ENROLLMENT = 100
  MAX_UNEXPECTED_STUDENTS = 5
  def over_enrolled?(course)
    return true if course.user_count > MAX_ENROLLMENT
    return false unless course.expected_students
    (course.user_count - course.expected_students) > MAX_UNEXPECTED_STUDENTS
  end
end
