# frozen_string_literal: true

require 'ostruct'

class CourseTrainingProgressManager
  # Courses before Spring 2016 used the old on-wiki training
  # instead of the dashboard-based training modules.
  TRAINING_BOOLEAN_CUTOFF_DATE = Date.new(2015, 12, 1)

  def initialize(course)
    @course = course
  end

  def course_training_progress(user)
    @user = user

    # For old courses, on-wiki training completion is tracked with User#trained?
    if off_dashboard_training?
      return @user.trained? ? nil : I18n.t('users.training_incomplete')
    end
    assigned_count = total_training_modules_for_course
    return if assigned_count.zero?
    completed_count = completed_training_modules_for_user_and_course
    description = I18n.t('users.training_modules_completed',
                         completed_count:, count: assigned_count)

    {
      assigned_count:,
      completed_count:,
      description:
    }
  end

  def course_exercise_progress(user)
    return if off_dashboard_training?

    @user = user
    assigned_count = total_exercise_modules_for_course
    return if assigned_count.zero?
    completed_count = completed_exercise_modules_for_user_and_course
    description = I18n.t('users.exercise_modules_completed',
                         completed_count:, count: assigned_count)

    {
      assigned_count:,
      completed_count:,
      description:
    }
  end

  def incomplete_assigned_modules(user)
    @user = user
    modules = incomplete_module_ids.map do |module_id|
      build_open_struct_for_module(module_id)
    end
    modules.sort_by(&:due_date)
  end

  private

  def off_dashboard_training?
    @off_dashboard_training ||= @course.start < TRAINING_BOOLEAN_CUTOFF_DATE &&
                                @course.type != 'VisitingScholarship'
  end

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
      training_module:,
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
    @assigned_module_ids ||= @course.training_modules.collect(&:id)
  end

  def incomplete_module_ids
    assigned_module_ids - completed_module_ids
  end

  def completed_training_modules_for_user_and_course
    TrainingModulesUsers
      .includes(:training_module)
      .where(user_id: @user.id)
      .where(training_module_id: training_modules_for_course)
      .where.not(completed_at: nil)
      .count { |tmu| tmu.training_module.training? }
  end

  def completed_exercise_modules_for_user_and_course
    TrainingModulesUsers
      .includes(:training_module)
      .where(user_id: @user.id)
      .where(training_module_id: exercise_modules_for_course)
      .count do |tmu|
        flags_hash = tmu.flags
        course_flags_hash = flags_hash[@course.id] || flags_hash
        course_flags_hash[:marked_complete] == true && tmu.training_module.exercise?
      end
  end

  def blocks_with_modules_for_course
    Block
      .joins(week: :course)
      .where.not('training_module_ids like ?', [].to_yaml)
      .where(weeks: { course_id: @course.id })
  end

  def module_ids_for_course
    blocks_with_modules_for_course
      .pluck(:training_module_ids)
      .flatten
      .uniq
  end

  def modules_for_course
    @modules_for_course ||= TrainingModule.where(id: module_ids_for_course)
  end

  def training_modules_for_course
    @training_modules_for_course ||= modules_for_course.select(&:training?)
  end

  def total_training_modules_for_course
    @total_training_modules_for_course ||= training_modules_for_course.count
  end

  def exercise_modules_for_course
    @exercise_modules_for_course ||= modules_for_course.select(&:exercise?)
  end

  def total_exercise_modules_for_course
    @total_exercise_modules_for_course ||= exercise_modules_for_course.count
  end

  def meetings_manager
    @meetings_manager ||= @course.meetings_manager
  end
end
