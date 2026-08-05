# frozen_string_literal: true

# What to report to Canvas for one student on one gradebook column: the AGS score
# payload, as keyword arguments for LtiServiceSession#post_score.
#
# Extracted from SyncLtiGrades because these are policy decisions, not sync
# mechanics — which columns the Dashboard may grade, what an activity's progress
# means, and when a submission rides along — and they had outgrown living inline.
#
# Three rules, each with a reason:
#
#   - Mechanical columns (an account is connected, a training is completed) carry
#     a real score. Everything else is student work whose quality only the
#     instructor can judge, so it reports Submitted + PendingManual with NO score:
#     Canvas creates the submission, leaves it ungraded, and queues it. Reporting
#     1/1 for a ticked box claimed a judgment nobody had made.
#   - `activityProgress` is derived from the score rather than always Completed.
#     The trainings roll-up pushes fractions, so a blanket Completed contradicted
#     the number beside it.
#   - The submission extension rides along on the FIRST push for a (column,
#     student), and only then. Canvas stores the launch URL only when the score
#     claims a new submission, and a new submission is a new attempt — so sending
#     it every time would pile up attempts and shove an already-graded submission
#     back into the needs-grading queue. Every column gets one, including the
#     mechanical ones: an instructor who opens any column in SpeedGrader would
#     otherwise meet Canvas's bare "No Preview Available" (operator decision
#     2026-08-05).
class LtiScorePayload
  def initialize(line_item:, context:, progress:, comment:, first_push:)
    @line_item = line_item
    @context = context
    @progress = progress
    @comment = comment
    @first_push = first_push
  end

  def to_h
    base = { lineitem_id: @line_item.lineitem_id, user_lti_id: @context.user_lti_id,
             comment: @comment, submission_url: submission_launch_url }
    return base.merge(for_grading) if @line_item.instructor_graded?

    base.merge(scored)
  end

  private

  def for_grading
    { activity_progress: 'Submitted', grading_progress: 'PendingManual' }
  end

  # `gradingProgress` stays FullyGraded either way: what the student has done so
  # far is fully graded, nothing is pending on this side.
  def scored
    { score_given: @progress.score_given, score_maximum: @progress.score_maximum,
      activity_progress: activity_progress }
  end

  def activity_progress
    @progress.score_given.to_f < @progress.score_maximum.to_f ? 'InProgress' : 'Completed'
  end

  # The URL Canvas stores as the submission's own, so opening a student's
  # submission launches us instead of showing "No Preview Available". Carries the
  # column's resource marker and NO identifier for the student, deliberately: this
  # URL is persisted inside Canvas, where a Wikipedia username must not go (the
  # same rule that keeps sandbox URLs out of score comments). The launch itself
  # says who is looking.
  def submission_launch_url
    return unless @first_push
    return if ENV['LTIAAS_DOMAIN'].blank?

    "https://#{ENV['LTIAAS_DOMAIN']}/lti/launch" \
      "?resource=#{CGI.escape(@line_item.resource_marker)}&submission=1"
  end
end
