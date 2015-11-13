class TrainedStudentsManager
  def initialize(course)
    @course = course
  end

  def students_without_overdue_training
    return [] unless @course.training_modules.any?
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
