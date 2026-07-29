# frozen_string_literal: true

# Computes a single (Block, User) AGS score payload for the LTIAAS grade
# sync. A block scores 1.0/1.0 if every considered TrainingModule attached
# to it is complete for that user; 0.0/1.0 otherwise. v1 considers a
# training-kind module complete when TrainingModulesUsers.completed_at is
# set, and an exercise-kind module complete when
# `flags[course_id][:marked_complete]` is truthy.
#
# Only the block's *exercise* modules are considered. Its training-kind modules
# are graded by the rolled-up "Wikipedia trainings" column, so requiring them
# here too would double-count them and zero out the exercise column on
# mixed-content blocks until the surrounding trainings happened to be complete.
# This used to be an `exercises_only:` flag, defaulting to false for the
# per-block gradebook layout, where one column represented a whole block; that
# layout is gone, so every caller wanted exercises-only.
#
# The comment field carries only a "[Late]" marker prefix when the block
# has a calculated due date in the past and the user has completed it.
# Score remains 1.0; Wiki Ed practice doesn't auto-penalize late training,
# but the marker shows up in the gradebook so instructors with their own
# policy can act. Otherwise the comment is nil.
#
# It deliberately does NOT include exercise sandbox URLs. Those URLs embed
# the student's Wikipedia username ("User:<username>/..."), and an AGS
# comment is stored in Canvas's gradebook (visible to TAs, co-instructors,
# the registrar, and CSV exports) — a FERPA correlation we don't want.
# Instructors reach a student's sandbox through the role-gated in-Canvas
# assignment_view instead, which serves the link from the Dashboard rather
# than persisting it in Canvas.
#
# `signature` is a stable hash of (score_given, comment) for dedup —
# SyncLtiGrades skips a POST when the stored LtiScoreSignature for this
# (line item, student) matches what we'd push next.
class LtiBlockProgress
  attr_reader :score_given, :score_maximum, :comment

  SCORE_MAXIMUM = 1.0

  # `completions`, when given, is this user's TrainingModulesUsers preloaded by
  # the caller and keyed by `training_module_id` — so a roster can look up
  # completion in memory instead of a per-(student, module) query. When nil,
  # each module is looked up on demand (the single-user path).
  def initialize(block, user, completions: nil)
    @block = block
    @user = user
    @course = block.course
    @completions = completions
    @training_modules = block.training_modules.to_a.select(&:exercise?)
    @score_maximum = SCORE_MAXIMUM
    @score_given = compute_score
    @comment = compute_comment
  end

  def signature
    @signature ||= Digest::SHA1.hexdigest("#{@score_given}|#{@comment}")
  end

  def gradable?
    @training_modules.any?
  end

  private

  def compute_score
    return 0.0 if @training_modules.empty?
    return SCORE_MAXIMUM if @training_modules.all? { |m| module_complete?(m) }

    0.0
  end

  def compute_comment
    '[Late]' if late_completion?
  end

  def late_completion?
    return false unless @score_given >= SCORE_MAXIMUM

    due = @block.calculated_due_date
    return false if due.nil?

    Time.zone.today > due
  end

  def module_complete?(mod)
    tmu = @completions ? @completions[mod.id] : TrainingModulesUsers.find_by(user: @user,
                                                                             training_module: mod)
    return false unless tmu

    return tmu.flags.dig(@course.id, :marked_complete) ? true : false if mod.exercise?

    tmu.completed_at.present?
  end
end
