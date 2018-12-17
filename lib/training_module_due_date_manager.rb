# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training_progress_manager"

class TrainingModuleDueDateManager
  def initialize(opts)
    @course = opts[:course]
    @training_module = opts[:training_module]
    @user = opts[:user]
    return unless @user.present?
    @tmu = TrainingModulesUsers.find_by(user_id: @user.id,
                                        training_module_id: @training_module.id)
  end

  DEADLINE_STATUSES = {
    complete: 'complete',
    overdue: 'overdue'
  }.freeze

  def computed_due_date(block = course_block_for_module)
    block.calculated_due_date
  end

  def overdue?
    !module_completed? && Time.zone.now.to_date > computed_due_date
  end

  def deadline_status
    return DEADLINE_STATUSES[:complete] if progress_manager.module_completed?
    overdue? ? DEADLINE_STATUSES[:overdue] : nil
  end

  # earliest due date (if user belongs to multiple
  # courses where module is assigned)
  def overall_due_date
    blocks = blocks_with_module_assigned(@training_module)
    blocks.collect(&:calculated_due_date).min
  end

  def blocks_with_module_assigned(training_module)
    blocks_with_training_modules_for_user.select do |block|
      block.training_module_ids.include?(training_module.id)
    end
  end

  def module_progress
    progress_manager.module_progress
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
    @pm ||= TrainingProgressManager.new(@user, @training_module,
                                        training_module_user: @tmu || :none)
  end

  def course_block_for_module
    @block ||= @course.blocks.find do |block|
      block.training_module_ids.include?(@training_module.id)
    end
  end
end
