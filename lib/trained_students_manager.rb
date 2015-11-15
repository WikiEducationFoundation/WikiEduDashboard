class TrainedStudentsManager
  def initialize(course)
    @course = course
  end

  def students_without_overdue_training
    students_scope.count
  end

  private

  def students_scope
    # NOTE: Here we can use .students instead of .students_without_nonstudents,
    # because by the time the new training system was introduced, users were
    # no longer allowed to have both student and nonstudent roles in the same
    # course.
    return @course.students unless @course.training_modules.any?
    @course.students.select do |student|
      @course.training_modules.select do |training_module|
        man = TrainingModuleDueDateManager.new(
                course: @course,
                training_module: training_module,
                user: student
              )
        man.overdue?
      end.empty?
    end
  end
end
