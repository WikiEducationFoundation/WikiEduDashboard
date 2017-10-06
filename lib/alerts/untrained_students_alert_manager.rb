# frozen_string_literal: true

class UntrainedStudentsAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next unless course.type == 'ClassroomProgramCourse'
      next if Alert.exists?(course_id: course.id, type: 'UntrainedStudentsAlert')
      next unless training_very_overdue?(course)
      alert = Alert.create(type: 'UntrainedStudentsAlert', course_id: course.id)
      alert.send_email
    end
  end

  private

  UNTRAINED_GRACE_PERIOD = 30
  EXPECTED_COMPLETION_RATE = 0.75
  def training_very_overdue?(course)
    return false if course.user_count.zero?
    completion_rate = course.trained_count.to_f / course.user_count
    return false unless completion_rate < EXPECTED_COMPLETION_RATE
    latest_training_assignment_date = dates_of_overdue_trainings(course).last
    return false if latest_training_assignment_date.nil?
    return false unless latest_training_assignment_date < UNTRAINED_GRACE_PERIOD.days.ago
    true
  end

  def dates_of_overdue_trainings(course)
    training_blocks = course.blocks.reject { |block| block.training_module_ids.empty? }
    assignment_dates = training_blocks.map do |block|
      block.week.meeting_dates.last
    end
    # Courses without enough meeting dates to fit all Week records can have nil
    # assignment dates.
    assignment_dates.reject!(&:nil?)
    assignment_dates.select { |date| date < Time.now }.sort
  end
end
