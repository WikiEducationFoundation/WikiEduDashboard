require_relative 'training_progress_manager'

class TrainingModuleDueDateManager
  def initialize(opts)
    @course = opts[:course]
    @training_module = opts[:training_module]
    @user = opts[:user]
    @tmu = TrainingModulesUsers.find_by(
      user_id: @user.id,
      training_module_id: @training_module.id
    ) if @user.present?
  end

  DEADLINE_STATUSES = {
    complete: 'complete',
    overdue: 'overdue'
  }

  def computed_due_date(block = course_block_for_module)
    return block.due_date if block.due_date.present?
    # an assignment due the end of the first week
    # is due the end of the week the timeline starts
    # (0 weeks from timeline start)
    weeks_from_start = (block.week.order - 1).to_i
    (block.week.course.timeline_start + weeks_from_start.weeks)
      .to_date.end_of_week(:sunday)
  end

  def overdue?
    !progress_manager.module_completed? && Date.today > computed_due_date
  end

  def deadline_status
    return DEADLINE_STATUSES[:complete] if progress_manager.module_completed?
    overdue? ? DEADLINE_STATUSES[:overdue] : nil
  end

  # earliest due date (if user belongs to multiple
  # courses where module is assigned)
  def overall_due_date
    blocks = blocks_with_module_assigned(@training_module)
    blocks.collect { |block| computed_due_date(block) }.sort.first
  end

  def blocks_with_module_assigned(training_module)
    blocks_with_training_modules_for_user.select do |block|
      block.training_module_ids.include?(training_module.id)
    end
  end

  private

  def blocks_with_training_modules_for_user
    return [] unless @user.present?
    Block.joins(week: { course: :courses_users })
      .where(courses_users: { user_id: @user.id })
      .where.not('training_module_ids = ?', [].to_yaml)
  end


  def progress_manager
    pm = TrainingProgressManager.new(@user, @training_module)
  end

  def course_block_for_module
    Block.joins(week: :course)
      .where(weeks: { course_id: @course.id })
      .find { |block| block.training_module_ids.include?(@training_module.id) }
  end
end
