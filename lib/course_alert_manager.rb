class CourseAlertManager
  def initialize
    @courses_to_check = Course.strictly_current
  end

  def create_no_students_alerts
    @courses_to_check.each do |course|
      next unless course.students.empty?
      next unless within_no_student_alert_period?(course.timeline_start)

      next if Alert.exists?(course_id: course.id, type: 'NoEnrolledStudentsAlert')
      alert = Alert.create(type: 'NoEnrolledStudentsAlert', course_id: course.id)
      alert.email_course_admins
    end
  end

  def create_untrained_students_alerts
    @courses_to_check.each do |course|
      next if Alert.exists?(course_id: course.id, type: 'UntrainedStudentsAlert')
      next unless training_very_overdue?(course)
      alert = Alert.create(type: 'UntrainedStudentsAlert', course_id: course.id)
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

  UNTRAINED_GRACE_PERIOD = 19
  EXPECTED_COMPLETION_RATE = 0.75
  def training_very_overdue?(course)
    return false if course.user_count == 0
    completion_rate = course.trained_count.to_f / course.user_count
    return false unless completion_rate < EXPECTED_COMPLETION_RATE
    latest_training_assignment_date = dates_of_overdue_trainings(course).last
    return false unless latest_training_assignment_date < UNTRAINED_GRACE_PERIOD.days.ago
    true
  end

  def dates_of_overdue_trainings(course)
    training_blocks = course.blocks.select { |block| !block.training_module_ids.empty? }
    assignment_dates = training_blocks.map do |block|
      block.week.meeting_dates.last
    end
    assignment_dates.select { |date| date < Time.now }.sort
  end
end
