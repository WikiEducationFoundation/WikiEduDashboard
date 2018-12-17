# frozen_string_literal: true

class FirstStudentAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next unless course.type == 'ClassroomProgramCourse'
      next if course.students.empty?
      next if Alert.exists?(course_id: course.id, type: 'FirstEnrolledStudentAlert')

      next unless first_enrollment_is_recent?(course)

      alert = Alert.create(type: 'FirstEnrolledStudentAlert', course_id: course.id)
      alert.send_email
    end
  end

  private

  # Only create an alert if the first enrollment happened in the last few days.
  RECENT_ENROLLMENT_DAYS = 3
  def first_enrollment_is_recent?(course)
    first_enrollment = course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE).first
    RECENT_ENROLLMENT_DAYS.days.ago < first_enrollment.created_at
  end
end
