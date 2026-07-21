# frozen_string_literal: true

# Bundles the data for the in-Canvas assignment view of the rolled-up
# "Wikipedia trainings" (TrainingProgress) gradebook column. Instructors
# see each linked student's completed-trainings count; a student sees
# their own progress plus a link out to the course timeline where the
# trainings live. Counts come from LtiTrainingProgress — the same
# calculation that drives the pushed AGS score — so this view can't
# disagree with the gradebook.
class TrainingsAssignmentViewContext
  Row = Struct.new(:name, :completed_count, :total_count, keyword_init: true) do
    def done?
      total_count.positive? && completed_count == total_count
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

  private

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
