# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/article_facts"
require_dependency "#{Rails.root}/lib/student_progress/exercise_facts"
require_dependency "#{Rails.root}/lib/student_progress/links"
require_dependency "#{Rails.root}/lib/student_progress/timeline"

# Bundles the data the in-Canvas `assignment_view` needs for one gradebook
# line item, so the controller action and its views stay thin. Produces a
# single student's row (student-facing panel) or one row per linked student
# (instructor roster).
#
# Handles Block-backed line items — the per-exercise gradebook columns,
# including "Evaluate Wikipedia". The sentinel columns have their own
# contexts (SetupAssignmentViewContext, TrainingsAssignmentViewContext).
class AssignmentViewContext
  include LtiRosterFocus

  StudentRow = Struct.new(:name, :username, :progress_state, :sandbox_url,
                          :assigned_articles, keyword_init: true) do
    def completed?
      progress_state == :complete
    end
  end

  # Exercises whose outcome is *which article* the student took on
  # (StudentProgress::Timeline::ARTICLE_SELECTION_SLUGS). "Completed" is a
  # useless thing to report for these: the instructor wants to know that this
  # student is writing about Foo, and that this other student hasn't chosen
  # anything yet. Both current selection exercises are listed — one where
  # students pick from an instructor's list (no sandbox of its own) and one
  # where they draft candidates in a sandbox (which still renders alongside).
  ARTICLE_SELECTION_SLUGS = StudentProgress::Timeline::ARTICLE_SELECTION_SLUGS

  # The stages of the writing process where the shared article panel belongs —
  # the whole state of the student's article (bibliography, outline, draft, and
  # what they've written live) rather than this one exercise's tick. Operator's
  # list, 2026-08-03: choosing the article, the bibliography, the outline, and
  # continuing to improve.
  ARTICLE_PANEL_SLUGS = (ARTICLE_SELECTION_SLUGS +
                         %w[bibliography-exercise outline-exercise
                            continue-improving-exercise]).freeze

  attr_reader :line_item, :block, :course

  def initialize(line_item:, user:, instructor:, focus_user: nil)
    @line_item = line_item
    @user = user
    @instructor = instructor
    @focus_user = focus_user
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

  # Whether this column reports article assignments rather than completion. The
  # views swap the status cell for the article list; the pushed AGS score is
  # untouched — completion still drives that, so the gradebook and this view
  # continue to agree about what was submitted.
  def article_selection?
    exercise_modules.any? { |mod| ARTICLE_SELECTION_SLUGS.include?(mod.slug) }
  end

  # Whether the drill-down carries the shared article panel: every piece of the
  # student's article work, not just this exercise's own state.
  def article_panel?
    exercise_modules.any? { |mod| ARTICLE_PANEL_SLUGS.include?(mod.slug) }
  end

  # The launching student's own row, for the student-facing panel.
  def student_panel
    row_for(@user, name: @user.username)
  end

  # One row per linked student on this binding, for the instructor roster.
  def roster
    student_contexts.map { |context| row_for(context.user, name: context.user.username) }
  end

  # Some exercises happen at a dedicated in-app page (e.g. the fact
  # verification exercise's /courses/<slug>/verify_claim) rather than in a
  # user sandbox; nil for sandbox-based exercises. When present, the student
  # panel is just status + a button out to this URL.
  def exercise_url
    mod = exercise_modules.find { |m| m.exercise_path.present? }
    return unless mod

    StudentProgress::Links.exercise_path_url(@course, mod)
  end

  # Sandbox-based (mark-complete) exercises keep their how-to instructions in
  # the exercise module's own training page. The student panel links to it
  # prominently alongside the sandbox, since the sandbox alone doesn't explain
  # the task. nil for dedicated-page exercises — their in-app page (exercise_url)
  # carries the instructions itself.
  def instructions_url
    mod = exercise_modules.find(&:sandbox_location)
    return unless mod

    StudentProgress::Links.training_url(@course, mod)
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
                   sandbox_url: sandbox_url_for(user),
                   assigned_articles: assigned_articles_for(user))
  end

  # This student's assigned articles and the state of their work on each — the
  # `editing` role only, since a `reviewing` assignment is the peer-review stage
  # and has its own column. Empty (and cheap) for columns that report neither.
  def assigned_articles_for(user)
    return [] unless article_selection? || article_panel?

    article_work.articles_for(user)
  end

  def article_work
    @article_work ||= StudentProgress::ArticleFacts.new(progress_roster)
  end

  # Everything the rows read, loaded once for the roster plus the panel's own
  # user, so a 30-student roster doesn't run queries per row.
  def progress_roster
    @progress_roster ||= StudentProgress::Roster.new(
      course: @course, user_ids: student_contexts.map(&:user_id) + [@user&.id]
    )
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

  # Reuses the same completion logic that drives the pushed AGS score, so the
  # roster can't disagree with the gradebook.
  def completed_for?(user)
    return false if @block.nil?

    LtiBlockProgress.new(@block, user, completions: progress_roster.completions_for(user.id),
                                       training_modules: exercise_modules)
                    .score_given >= 1.0
  end

  # Only the fact-verification exercise has a "started" signal (see
  # StudentProgress::ExerciseFacts#in_progress?); sandbox exercises stay :none
  # until complete.
  def exercise_in_progress?(user)
    exercise_modules.any? { |mod| exercise_facts.in_progress?(user, mod) }
  end

  def exercise_facts
    @exercise_facts ||= StudentProgress::ExerciseFacts.new(progress_roster)
  end

  # Built even before the student starts, so the link points to where their
  # work will live. Exercises carry one sandbox_location each.
  def sandbox_url_for(user)
    mod = exercise_modules.find(&:sandbox_location)
    return unless mod

    StudentProgress::Links.exercise_sandbox_url(@course, user, mod)
  end

  # Wikipedia-linked students on this binding, excluding instructors/admins,
  # ordered by display name for a stable roster.
  def student_contexts
    @student_contexts ||=
      focused(@binding.linked_student_contexts
                      .select(&:user)
                      .sort_by { |context| context.user.username.downcase })
  end
end
