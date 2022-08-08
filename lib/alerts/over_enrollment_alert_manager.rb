# frozen_string_literal: true

class OverEnrollmentAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next unless course.type == 'ClassroomProgramCourse'
      next unless over_enrolled?(course)
      next if Alert.exists?(course:, type: 'OverEnrollmentAlert', resolved: false)

      alert = Alert.create(type: 'OverEnrollmentAlert', course:)
      alert.email_course_admins
    end
  end

  private

  def over_enrolled?(course)
    return true if course.user_count > OverEnrollmentAlert::MAX_ENROLLMENT
    return false unless course.expected_students
    (course.user_count - course.expected_students) > OverEnrollmentAlert::MAX_UNEXPECTED_STUDENTS
  end
end
