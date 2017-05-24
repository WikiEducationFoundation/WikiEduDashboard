# frozen_string_literal: true

class TrainedStudentsManager
  def initialize(course)
    @course = course
  end

  def students_up_to_date_with_training
    @course.students - students_with_overdue_training
  end

  def students_with_overdue_training
    return [] unless @course.training_modules.any?
    @course.students.select do |student|
      @course.training_modules.any? do |training_module|
        TrainingModuleDueDateManager.new(
          course: @course,
          training_module: training_module,
          user: student
        ).overdue?
      end
    end
  end
end
