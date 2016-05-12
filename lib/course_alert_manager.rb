require "#{Rails.root}/lib/alerts/productive_course_alert_manager"
require "#{Rails.root}/lib/alerts/no_students_alert_manager"
require "#{Rails.root}/lib/alerts/untrained_students_alert_manager"

class CourseAlertManager
  def initialize
    @courses_to_check = Course.strictly_current
  end

  def create_no_students_alerts
    NoStudentsAlertManager.new(@courses_to_check).create_alerts
  end

  def create_untrained_students_alerts
    UntrainedStudentsAlertManager.new(@courses_to_check).create_alerts
  end

  def create_productive_course_alerts
    ProductiveCourseAlertManager.new(@courses_to_check).create_alerts
  end
end
