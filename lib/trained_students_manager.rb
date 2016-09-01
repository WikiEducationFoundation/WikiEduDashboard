# frozen_string_literal: true
class TrainedStudentsManager
  def initialize(course)
    @course = course
  end

  def students_up_to_date_with_training
    @course.students - students_with_overdue_training
  end

  def students_with_overdue_training
    # NOTE: Here we can use .students instead of .students_without_nonstudents,
    # because by the time the new training system was introduced, users were
    # no longer allowed to have both student and nonstudent roles in the same
    # course.
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
