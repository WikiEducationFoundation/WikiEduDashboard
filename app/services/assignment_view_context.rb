# frozen_string_literal: true

# Bundles the data the in-Canvas `assignment_view` needs for one gradebook
# line item, so the controller action and its views stay thin. Produces a
# single student's row (student-facing panel) or one row per linked student
# (instructor roster).
#
# Handles Block-backed line items — the per-exercise gradebook columns,
# including "Evaluate Wikipedia". The sentinel columns have their own
# contexts (SetupAssignmentViewContext, TrainingsAssignmentViewContext).
class AssignmentViewContext
  StudentRow = Struct.new(:name, :username, :progress_state, :sandbox_url,
                          keyword_init: true) do
    def completed?
      progress_state == :complete
    end
  end

  attr_reader :line_item, :block, :course

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

  # Some exercises happen at a dedicated in-app page (e.g. the fact
  # verification exercise's /courses/<slug>/verify_claim) rather than in a
  # user sandbox; nil for sandbox-based exercises. When present, the student
  # panel is just status + a button out to this URL.
  def exercise_url
    mod = exercise_modules.find { |m| m.exercise_path.present? }
    return unless mod

    "/courses/#{@course.slug}/#{mod.exercise_path}"
  end

  # Sandbox-based (mark-complete) exercises keep their how-to instructions in
  # the exercise module's own training page. The student panel links to it
  # prominently alongside the sandbox, since the sandbox alone doesn't explain
  # the task. nil for dedicated-page exercises — their in-app page (exercise_url)
  # carries the instructions itself.
  def instructions_url
    mod = exercise_modules.find(&:sandbox_location)
    return unless mod

    "/training/#{@course.training_library_slug}/#{mod.slug}" \
      "?return_to=#{CGI.escape("/courses/#{@course.slug}")}"
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
                   progress_state: progress_state_for(user),
                   sandbox_url: sandbox_url_for(user))
  end

  # :complete once the exercise is marked done, :partial while a dedicated-page
  # exercise is under way (the student has started but not submitted), else
  # :none — so the pill and next-step read truthfully rather than showing
  # "not started" to someone mid-exercise.
  def progress_state_for(user)
    return :complete if completed_for?(user)
    return :partial if exercise_in_progress?(user)

    :none
  end

  # Reuses the same completion logic — including the same exercises_only
  # setting — that drives the pushed AGS score, so the roster can't disagree
  # with the gradebook. (In per_block mode a block's column grades trainings
  # too; in the roll-up modes it grades only the exercises.)
  def completed_for?(user)
    return false if @block.nil?

    LtiBlockProgress.new(@block, user, exercises_only: @binding.rolled_up_trainings?)
                    .score_given >= 1.0
  end

  # In-progress is only detectable for the fact-verification exercise: taking a
  # claim creates a VerificationClaimAssignment (a re-pointable cursor), and
  # submitting the response is what marks the module complete. Sandbox exercises
  # have no comparable "started" signal, so they stay :none until complete.
  def exercise_in_progress?(user)
    return false unless fact_verification_block?

    VerificationClaimAssignment.exists?(user_id: user.id, course_id: @course.id)
  end

  def fact_verification_block?
    exercise_modules.any? { |mod| mod.exercise_path == 'verify_claim' }
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
    @binding.linked_student_contexts
            .select(&:user)
            .sort_by { |context| (context.name.presence || context.user.username).downcase }
  end
end
