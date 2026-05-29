# frozen_string_literal: true

# Bundles the data the in-Canvas `assignment_view` needs for one gradebook
# line item, so the controller action and its views stay thin. Produces a
# single student's row (student-facing panel) or one row per linked student
# (instructor roster).
#
# v1 supports Block-backed line items — the per-exercise gradebook columns,
# including "Evaluate Wikipedia". The lumped TrainingProgress line item has
# no single block to break down and is routed to the orphan view by the
# controller instead; per-training drill-down is a follow-up.
class AssignmentViewContext
  StudentRow = Struct.new(:name, :username, :completed, :sandbox_url,
                          keyword_init: true) do
    def completed?
      completed
    end
  end

  attr_reader :line_item, :block

  def initialize(line_item:, user:, instructor:)
    @line_item = line_item
    @user = user
    @instructor = instructor
    @binding = line_item.lti_course_binding
    @course = @binding.course
    @block = resolve_block
  end

  def instructor?
    @instructor
  end

  def title
    @line_item.label
  end

  # The launching student's own row, for the student-facing panel.
  def student_panel
    row_for(@user, name: @user.username)
  end

  # One row per linked student on this binding, for the instructor roster.
  def roster
    student_contexts.map do |context|
      row_for(context.user, name: context.name.presence || context.user.username)
    end
  end

  private

  def resolve_block
    return unless @line_item.gradable_type == 'Block'

    Block.find_by(id: @line_item.gradable_id)
  end

  def exercise_modules
    @exercise_modules ||= @block ? @block.training_modules.select(&:exercise?) : []
  end

  def row_for(user, name:)
    StudentRow.new(name:, username: user.username,
                   completed: completed_for?(user),
                   sandbox_url: sandbox_url_for(user))
  end

  # Reuses the same completion logic that drives the pushed AGS score, so
  # the roster can't disagree with the gradebook.
  def completed_for?(user)
    return false if @block.nil?

    LtiBlockProgress.new(@block, user, exercises_only: true).score_given >= 1.0
  end

  # Built even before the student starts, so the link points to where their
  # work will live. Exercises carry one sandbox_location each.
  def sandbox_url_for(user)
    mod = exercise_modules.find(&:sandbox_location)
    return unless mod

    "#{@course.home_wiki.base_url}/wiki/User:#{user.url_encoded_username}/#{mod.sandbox_location}"
  end

  # Wikipedia-linked students on this binding, excluding instructors/admins,
  # ordered by display name for a stable roster.
  def student_contexts
    @binding.lti_contexts.linked
            .select { |context| context.user && !instructor_context?(context) }
            .sort_by { |context| (context.name.presence || context.user.username).downcase }
  end

  def instructor_context?(context)
    Array(context.roles).any? do |role|
      LtiSession::INSTRUCTOR_ROLES.any? { |suffix| role.end_with?(suffix) }
    end
  end
end
