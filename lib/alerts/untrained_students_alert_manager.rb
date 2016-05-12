class UntrainedStudentsAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next if Alert.exists?(course_id: course.id, type: 'UntrainedStudentsAlert')
      next unless training_very_overdue?(course)
      alert = Alert.create(type: 'UntrainedStudentsAlert', course_id: course.id)
      alert.email_course_admins
    end
  end

  private

  UNTRAINED_GRACE_PERIOD = 19
  EXPECTED_COMPLETION_RATE = 0.75
  def training_very_overdue?(course)
    return false if course.user_count == 0
    completion_rate = course.trained_count.to_f / course.user_count
    return false unless completion_rate < EXPECTED_COMPLETION_RATE
    latest_training_assignment_date = dates_of_overdue_trainings(course).last
    return false if latest_training_assignment_date.nil?
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
