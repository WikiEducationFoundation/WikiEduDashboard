# frozen_string_literal: true

# Computes a single (Block, User) completion state for the LTIAAS grade sync.
# A block scores 1.0/1.0 if every considered TrainingModule attached to it is
# complete for that user; 0.0/1.0 otherwise. An exercise-kind module counts as
# complete when `flags[course_id][:marked_complete]` is truthy.
#
# That 1.0 is NOT a grade, and since 2026-08-03 it does not reach Canvas as one.
# Exercise work is evaluated by the instructor, so SyncLtiGrades reports a
# complete block as Submitted + PendingManual with no score, and Canvas leaves
# the submission ungraded in the needs-grading queue. The score here is read as
# "did the student finish it" — see LtiScorePayload#for_grading.
#
# Only the block's *exercise* modules are considered. Its training-kind modules
# are graded by the rolled-up "Wikipedia trainings" column, so requiring them
# here too would double-count them and zero out the exercise column on
# mixed-content blocks until the surrounding trainings happened to be complete.
# This used to be an `exercises_only:` flag, defaulting to false for the
# per-block gradebook layout, where one column represented a whole block; that
# layout is gone, so every caller wanted exercises-only.
#
# `comment` is always nil, and there is no lateness marker. There used to be a
# "[Late]" prefix, but it was computed from the score being at maximum plus the
# due date having passed — no completion time was consulted — so once a due date
# went by, every student who had finished *on time* acquired the marker. Since
# this only grades exercises now, and `TrainingModulesUsers#mark_completion`
# records no timestamp for a per-course exercise completion
# (`flags[course_id] = { marked_complete: value }`), lateness is not computable
# here at all. Re-introducing it needs a completion timestamp first; a marker
# that is wrong for the whole roster is worse than none, because the gradebook
# comment feeds real grade decisions. See docs/canvas_integration_todos.md.
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
  # `comment` is part of the progress duck type SyncLtiGrades posts (alongside
  # LtiSetupProgress and LtiTrainingProgress, which do set one); it stays nil
  # here. A blank comment is left off the AGS payload entirely.
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

  def module_complete?(mod)
    tmu = @completions ? @completions[mod.id] : TrainingModulesUsers.find_by(user: @user,
                                                                             training_module: mod)
    return false unless tmu

    return tmu.flags.dig(@course.id, :marked_complete) ? true : false if mod.exercise?

    tmu.completed_at.present?
  end
end
