# frozen_string_literal: true

require_relative 'training_progress_manager'

class TrainingModuleDueDateManager
  def initialize(opts)
    @course = opts[:course]
    @training_module = opts[:training_module]
    @user = opts[:user]
    if @user.present?
      @tmu = TrainingModulesUsers.find_by(
        user_id: @user.id,
        training_module_id: @training_module.id
      )
    end
    @meetings_manager = opts[:course_meetings_manager]
  end

  DEADLINE_STATUSES = {
    complete: 'complete',
    overdue: 'overdue'
  }.freeze

  def computed_due_date(block = course_block_for_module)
    block.calculated_due_date
  end

  def overdue?
    !module_completed? && Date.today > computed_due_date
  end

  def deadline_status
    return DEADLINE_STATUSES[:complete] if progress_manager.module_completed?
    overdue? ? DEADLINE_STATUSES[:overdue] : nil
  end

  # earliest due date (if user belongs to multiple
  # courses where module is assigned)
  def overall_due_date
    blocks = blocks_with_module_assigned(@training_module)
    blocks.collect(&:calculated_due_date).sort.first
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
         .where(courses_users: { user_id: @user.id, role: CoursesUsers::Roles::STUDENT_ROLE })
         .where.not('training_module_ids = ?', [].to_yaml).includes(:week)
  end

  def module_completed?
    return @tmu.completed_at.present? if @tmu.present?
    progress_manager.module_completed?
  end

  def progress_manager
    @pm ||= TrainingProgressManager.new(@user, @training_module)
    @pm
  end

  def course_block_for_module
    @block ||= Block.joins(week: :course)
                    .where(weeks: { course: @course })
                    .find { |block| block.training_module_ids.include?(@training_module.id) }
  end
end
