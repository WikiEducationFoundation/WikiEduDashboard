require 'ostruct'

class CourseTrainingProgressManager
  # Courses before Spring 2016 used the old on-wiki training
  # instead of the dashboard-based training modules.
  TRAINING_BOOLEAN_CUTOFF_DATE = Date.new(2015, 12, 01)

  def initialize(user, course)
    @user = user
    @course = course
  end

  def course_training_progress
    # For old courses, on-wiki training completion is tracked with User#trained?
    if @course.start < TRAINING_BOOLEAN_CUTOFF_DATE
      return @user.trained? ? nil : I18n.t('users.training_incomplete')
    end
    assigned_count = total_modules_for_course
    return if assigned_count == 0
    completed_count = completed_modules_for_user_and_course
    I18n.t('users.training_modules_completed', completed_count: completed_count,
                                               assigned_count: assigned_count)
  end

  def next_upcoming_assigned_module
    upcoming_block_mods = blocks_with_modules_for_course
                          .where('due_date > ?', Date.today)
    return unless upcoming_block_mods.any?
    block = upcoming_block_mods
            .order(:due_date).first
    build_open_struct_if_module_not_completed(block)
  end

  def first_overdue_module
    block = blocks_with_modules_for_course
            .where('due_date < ?', Date.today)
            .first
    build_open_struct_if_module_not_completed(block)
  end

  private

  def build_open_struct_if_module_not_completed(block)
    return unless block
    tm_id = block.training_module_ids.first
    return if all_training_modules_completed?(tm_id)
    tm = TrainingModule.find(tm_id)
    OpenStruct.new(
      title: tm.name,
      link: "/library/students/#{tm.slug}",
      due_date: block.due_date.strftime('%m/%d/%Y')
    )
  end

  def all_training_modules_completed?(tm_id)
    TrainingModulesUsers.where(
      user_id: @user.id,
      training_module_id: tm_id
    ).where.not(completed_at: nil).present?
  end

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
