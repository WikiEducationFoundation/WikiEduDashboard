class TrainedStudentsManager
  def initialize(course)
    @course = course
  end

  def students_without_overdue_training
    students_scope.count
  end

  private

  def students_scope
    return @course.students_without_nonstudents unless @course.training_modules.any?
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
