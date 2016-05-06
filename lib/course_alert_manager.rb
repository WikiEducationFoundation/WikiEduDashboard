class CourseAlertManager
  def create_no_students_alerts
    courses_to_check = Course.current
    courses_to_check.each do |course|
      next unless course.students.empty?
      next unless within_no_student_alert_period?(course.timeline_start)

      next if Alert.exists?(course_id: course.id, type: 'NoEnrolledStudentsAlert')
      alert = Alert.create(type: 'NoEnrolledStudentsAlert', course_id: course.id)
      alert.email_course_admins
    end
  end

  private

  # Only create an alert if has been at least MIN_DAYS but less than
  # MAX_DAYS since the assignment start date.
  NO_STUDENT_ALERT_MIN_DAYS = 15
  NO_STUDENT_ALERT_MAX_DAYS = 22
  def within_no_student_alert_period?(date)
    return false unless date < NO_STUDENT_ALERT_MIN_DAYS.days.ago
    return false unless NO_STUDENT_ALERT_MAX_DAYS.days.ago < date
    true
  end
end
