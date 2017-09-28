# frozen_string_literal: true

require 'ostruct'

class CourseTrainingProgressManager
  # Courses before Spring 2016 used the old on-wiki training
  # instead of the dashboard-based training modules.
  TRAINING_BOOLEAN_CUTOFF_DATE = Date.new(2015, 12, 1)

  def initialize(user, course)
    @user = user
    @course = course
  end

  def course_training_progress
    # For old courses, on-wiki training completion is tracked with User#trained?
    if @course.start < TRAINING_BOOLEAN_CUTOFF_DATE && @course.type != 'VisitingScholarship'
      return @user.trained? ? nil : I18n.t('users.training_incomplete')
    end
    assigned_count = total_modules_for_course
    return if assigned_count.zero?
    completed_count = completed_modules_for_user_and_course
    I18n.t('users.training_modules_completed', completed_count: completed_count,
                                               count: assigned_count)
  end

  def incomplete_assigned_modules
    modules = incomplete_module_ids.map do |module_id|
      build_open_struct_for_module(module_id)
    end
    modules.sort_by(&:due_date)
  end

  private

  def build_open_struct_for_module(id)
    training_module = TrainingModule.find(id)
    OpenStruct.new(
      title: training_module.name,
      link: "/training/students/#{training_module.slug}",
      due_date: due_date(training_module).strftime('%Y-%m-%d')
    )
  end

  def due_date(training_module)
    due_date_manager_opts = {
      user: @user,
      course: @course,
      training_module: training_module,
      course_meetings_manager: meetings_manager
    }
    due_date_manager = TrainingModuleDueDateManager.new(due_date_manager_opts)
    due_date_manager.computed_due_date
  end

  def completed_module_ids
    TrainingModulesUsers
      .where(user_id: @user.id)
      .where.not(completed_at: nil)
      .pluck(:training_module_id)
  end

  def assigned_module_ids
    @course.training_modules.collect(&:id)
  end

  def incomplete_module_ids
    assigned_module_ids - completed_module_ids
  end

  def completed_modules_for_user_and_course
    TrainingModulesUsers
      .where(user_id: @user.id)
      .where(training_module_id: modules_for_course)
      .where.not(completed_at: nil)
      .count
  end

  def blocks_with_modules_for_course
    Block
      .joins(week: :course)
      .where.not('training_module_ids like ?', [].to_yaml)
      .where(weeks: { course_id: @course.id })
  end

  def modules_for_course
    blocks_with_modules_for_course
      .pluck(:training_module_ids)
      .flatten
      .uniq
  end

  def total_modules_for_course
    modules_for_course.count
  end

  def meetings_manager
    @meetings_manager ||= CourseMeetingsManager.new(@course)
    @meetings_manager
  end
end
