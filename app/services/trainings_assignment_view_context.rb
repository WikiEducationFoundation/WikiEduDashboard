# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training_module_due_date_manager"
require_dependency "#{Rails.root}/lib/training_progress_manager"

# Bundles the data for the in-Canvas assignment view of the rolled-up
# "Wikipedia trainings" (TrainingProgress) gradebook column. Instructors
# see each linked student's completed-trainings count; a student sees the
# same per-module table as the Students-tab details drawer — every assigned
# training in due-date order with its due date, their status, and a link
# straight to the module. Counts come from LtiTrainingProgress — the same
# calculation that drives the pushed AGS score — so this view can't
# disagree with the gradebook.
class TrainingsAssignmentViewContext
  Row = Struct.new(:name, :completed_count, :total_count, keyword_init: true) do
    def done?
      total_count.positive? && completed_count == total_count
    end
  end

  ModuleRow = Struct.new(:name, :due_date, :status, :completed, :training_url,
                         keyword_init: true) do
    def completed?
      completed
    end
  end

  attr_reader :line_item, :course

  def initialize(line_item:, user:, instructor:)
    @line_item = line_item
    @user = user
    @instructor = instructor
    @binding = line_item.lti_course_binding
    @course = @binding.course
  end

  def instructor?
    @instructor
  end

  def title
    @line_item.label
  end

  # One row per linked student, for the instructor roster.
  def roster
    student_contexts.map do |context|
      row_for(context.user, name: context.name.presence || context.user.username)
    end
  end

  # The launching student's own row.
  def student_panel
    row_for(@user, name: @user.username)
  end

  # The launching student's per-module table, mirroring the Students-tab
  # details drawer: due-date order, each row linking to the module itself.
  def viewer_training_rows
    rows = viewer_progress.training_modules.map { |mod| viewer_module_row(mod) }
    rows.sort_by { |row| [row.due_date ? 0 : 1, row.due_date || Date.jd(0), row.name] }
  end

  # What the roll-up covers, for the instructor view.
  def training_module_names
    viewer_progress.training_modules.map(&:name)
  end

  private

  def viewer_progress
    @viewer_progress ||= LtiTrainingProgress.new(@course, @user)
  end

  # Same sources as the Students-tab drawer (TrainingStatusController):
  # due date from the module's timeline block, status strings from
  # TrainingProgressManager.
  def viewer_module_row(mod)
    due_date = TrainingModuleDueDateManager.new(course: @course, training_module: mod,
                                                user: @user).computed_due_date
    progress = TrainingProgressManager.new(@user, mod)
    ModuleRow.new(name: mod.name, due_date:, status: progress.status,
                  completed: progress.module_completed?,
                  training_url: "/training/#{@course.training_library_slug}/#{mod.slug}")
  end

  def row_for(user, name:)
    progress = LtiTrainingProgress.new(@course, user)
    Row.new(name:, completed_count: progress.completed_count,
            total_count: progress.total_count)
  end

  # Wikipedia-linked students on this binding, ordered by display name.
  def student_contexts
    @binding.linked_student_contexts
            .select(&:user)
            .sort_by { |context| (context.name.presence || context.user.username).downcase }
  end
end
