class CourseTrainingProgressManager

  def initialize(user, course)
    @user = user
    @course = course
  end


  def course_training_progress
    numerator = completed_modules_for_user_and_course
    denominator = total_modules_for_course
    "#{numerator}/#{denominator} training modules completed"
  end


  private

  def completed_modules_for_user_and_course
    TrainingModulesUsers.where(user_id: @user.id)
      .where(training_module_id: modules_for_course)
      .where.not(completed_at: nil)
      .count
  end

  def blocks_with_modules_for_course
    Block.joins(week: :course)
      .where.not('training_module_ids like ?', [].to_yaml)
      .where(weeks: { course_id: @course.id })
  end

  def modules_for_course
    blocks_with_modules_for_course.pluck(:training_module_ids)
      .flatten
      .uniq
  end

  def total_modules_for_course
    modules_for_course.count
  end

end
