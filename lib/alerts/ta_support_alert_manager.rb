# frozen_string_literal: true

class NoTaSupportAlertManager
  def initialize(tagged_courses)
    @tagged_courses = tagged_courses
  end

  def create_alerts
    @tagged_courses.each do |course|
      instructors = get_course_instructors(course)
      next unless within_no_ta_alert_period?(course.created_at)
      next unless instructors.size <= 1

      next if Alert.exists?(course:, type: 'NoTaEnrolledAlert')
      alert = Alert.create(type: 'NoTaEnrolledAlert', course:)
      alert.send_email
    end
  end

  private

  def get_course_instructors(course)
    CoursesUsers.where(course:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE).pluck(:user_id)
  end

  # Only create an alert if has been at least MIN_DAYS (7days)
  NO_TA_ALERT_MIN_DAYS = 7
  def within_no_ta_alert_period?(date)
    return false unless date < NO_TA_ALERT_MIN_DAYS.days.ago
    true
  end
end
