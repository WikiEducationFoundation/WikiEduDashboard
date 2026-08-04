# frozen_string_literal: true

# Pushes LTIAAS AGS scores for every linked student × active line item in
# one LtiCourseBinding. Deduplicates per-(student, line item) via
# LtiScoreSignature: the next push's signature is compared to the
# stored one and the POST is skipped when they match, so the 30-min
# cron only emits requests for actual state changes.
#
# Runs `SyncLtiLineItems` first as a precondition so the line-item set
# always reflects the current timeline before scores are posted at it.
#
# A binding without a stored serviceKey or a bound course is a no-op.
#
# Failure semantics, in three tiers:
#
#   - Whole-run failures (network/5xx, rate limit, auth) abort the sync, record
#     `last_grade_sync_error`, leave `last_grade_sync_at` where it was, and
#     re-raise so Sidekiq's retry gets a chance. These affect every push, so
#     swallowing them would report a fresh successful sync at the exact moment
#     no grade reached Canvas.
#   - Per-student permanent failures — an AGS rejection of one student's score
#     (LtiaasClientError) — are recorded, reported to Sentry, and skipped; the
#     run continues and finishes as a partial success — the timestamp advances
#     *and* the error field says what didn't land. Non-API errors (a progress
#     computation bug, a failed signature save) are NOT in this tier: they
#     abort the run, so a systemic application error gets a retry instead of
#     masquerading as N per-student rejections.
#   - A membership that's gone from the Canvas course is neither: expected,
#     logged, and not counted as a failure.
class SyncLtiGrades
  # Aborting tier. Order matters at the rescue sites: LtiaasRateLimitError and
  # LtiaasAuthError are both LtiaasClientError subclasses, so they have to be
  # matched before the generic per-score rescue.
  ABORTING_ERRORS = [LtiaasClient::LtiaasTransientError,
                     LtiaasClient::LtiaasRateLimitError,
                     LtiaasClient::LtiaasAuthError].freeze

  ERROR_TEXT_LIMIT = 1000

  attr_reader :binding

  def initialize(binding)
    @binding = binding
    @failures = []
    perform
  end

  private

  def perform
    return if @binding.course.nil?
    return if @binding.ltiaas_service_credentials.blank?

    SyncLtiLineItems.new(@binding) # bring line-item set up to date first
    @service = LtiServiceSession.new(@binding)
    push_scores_for_each_student
    record_completed_sync
    # Deliberately broader than ABORTING_ERRORS, which is only the *per-score*
    # classification. Anything that escapes this far failed the whole run —
    # including the line-item sync above, which can raise a plain
    # LtiaasClientError (any 4xx that isn't 401/403/429) or an ActiveRecord
    # error. Those used to propagate with neither field written, so the job
    # dead-lettered every cycle while LtiSyncStatus reported healthy.
  rescue StandardError => e
    record_aborted_sync(e)
    raise
  end

  # A clean pass clears the error field; a pass with rejected scores keeps the
  # timestamp honest (the pass did run) while saying how much didn't land. Only
  # `grade_sync_error?` — a boolean — is ever surfaced to users, so the text
  # here is a diagnostic for staff, not copy.
  def record_completed_sync
    @binding.update!(last_grade_sync_at: Time.current,
                     last_grade_sync_error: partial_failure_summary)
  end

  def partial_failure_summary
    return nil if @failures.empty?

    truncate_error("#{@failures.size} score push(es) failed; last: #{@failures.last}")
  end

  def record_aborted_sync(error)
    @binding.update!(last_grade_sync_error:
      truncate_error("#{error.class}: #{error.message}"))
  end

  def truncate_error(text)
    text.truncate(ERROR_TEXT_LIMIT)
  end

  def push_scores_for_each_student
    active_line_items.each do |line_item|
      contexts_for(line_item).each do |context|
        push_one(context, line_item)
      end
    end
  end

  # Only STUDENTS are ever graded — never instructors/staff. Canvas rejects an
  # AGS score for a non-student with a 422 ("User not found in course or is not
  # a student"), so posting the instructor's own setup mark used to fail every
  # cycle and flood Sentry. The setup indicator covers every discovered student
  # (a connected one scores 1.0; a not-yet-connected one is left ungraded by
  # skip_zero? rather than a failing 0). Every other line item grades only
  # students who have linked a Wikipedia account.
  def contexts_for(line_item)
    line_item.gradable_type == LtiLineItem::SETUP_TYPE ? student_contexts : linked_student_contexts
  end

  # Every learner membership (linked or not). Learners by LMS role, so staff and
  # Canvas observers/designers are both left out — posting a score for a
  # non-student is what Canvas rejects with the 422 handled below.
  def student_contexts
    @binding.lti_contexts.select(&:learner?)
  end

  def linked_student_contexts
    @binding.linked_student_contexts
  end

  # Bound only: a pending deep-link reservation has no lineitem_id yet, so
  # there is nothing to post a score at — and with the per-student rescue now
  # excluding non-API errors, letting one through would abort the whole run.
  def active_line_items
    LtiLineItem.bound.where(lti_course_binding_id: @binding.id, archived_at: nil)
  end

  # LTIAAS/Canvas 422 when the target user isn't a gradable student in the
  # course (removed from the roster, or not a student). Expected and handled,
  # not an error to report — otherwise a stale membership floods Sentry on
  # every 30-min cycle.
  MEMBERSHIP_GONE = /not found in (?:the )?course|not a student/i

  # No bare StandardError rescue here: only an AGS rejection of one score is a
  # per-student failure. A bug in progress computation or a signature-save
  # failure is systemic — swallowing it per-student let a broken deploy reject
  # every score while the run recorded a completed partial sync with no Sidekiq
  # retry. Those now escape to #perform's whole-run handler.
  def push_one(context, line_item)
    progress = compute_progress(line_item, context)
    return unless progress&.gradable?
    return if skip_zero?(progress, line_item, context)
    return if signature_unchanged?(line_item, context, progress.signature)

    post_score(context, line_item, progress)
    record_signature(line_item, context, progress.signature)
  rescue *ABORTING_ERRORS
    raise # whole-run failure; #perform records it and lets Sidekiq retry
  rescue LtiaasClient::LtiaasClientError => e
    return log_non_gradable(context, line_item) if membership_gone?(e)

    report_push_failure(e, context, line_item)
  end

  def membership_gone?(error)
    error.status_code == 422 && error.response_body.to_s.match?(MEMBERSHIP_GONE)
  end

  def log_non_gradable(context, line_item)
    Rails.logger.info(
      "[LTI grade sync] skipping non-gradable member: binding=#{@binding.id} " \
      "user_lti_id=#{context.user_lti_id} lineitem=#{line_item.lineitem_id}"
    )
  end

  def report_push_failure(error, context, line_item)
    @failures << "#{error.class} for user_lti_id=#{context.user_lti_id} " \
                 "lineitem=#{line_item.lineitem_id}"
    Sentry.capture_exception(
      error,
      extra: { binding_id: @binding.id, user_lti_id: context.user_lti_id,
               lineitem_id: line_item.lineitem_id }
    )
  end

  # Don't seed a counting zero for not-yet-done / not-connected work. Canvas
  # offers no LTI way to make our columns Complete/Incomplete or exclude them
  # from the course total (only the `submission_type` AGS extension is
  # writable), so a posted 0 reads as a failing 0% — e.g. a student who simply
  # hasn't connected their Wikipedia account yet would show 0% in the course.
  # Leaving it ungraded (blank) keeps it out of Canvas's total by default until
  # there's real progress. Who-hasn't-connected still shows in the in-Canvas
  # "Wikipedia account" roster. On a mechanical column a zero still posts once
  # we've recorded a score for this pair — that's a genuine correction downward,
  # e.g. an un-completed training.
  #
  # An instructor-graded column has no such correction to make: it reports
  # submission, not a score, and the grade belongs to the instructor. So
  # unfinished exercise work is simply never reported — including work that was
  # finished and then un-marked, where retracting the submission isn't something
  # AGS can express and overwriting the instructor's grade isn't ours to do.
  def skip_zero?(progress, line_item, context)
    return false unless progress.score_given.to_f.zero?
    return true if line_item.instructor_graded?

    first_push?(line_item, context)
  end

  def post_score(context, line_item, progress)
    return post_for_grading(context, line_item, progress) if line_item.instructor_graded?

    @service.post_score(
      lineitem_id: line_item.lineitem_id,
      user_lti_id: context.user_lti_id,
      score_given: progress.score_given,
      score_maximum: progress.score_maximum,
      comment: with_origin(progress.comment),
      activity_progress: activity_progress(progress)
    )
  end

  # Exercise work is evaluated by the instructor; the Dashboard only knows the
  # student said they finished it. Reporting that as 1/1 claimed a judgment
  # nobody had made and pre-empted the instructor's (operator decision
  # 2026-08-03). Submitted + PendingManual with NO score is the AGS way to say
  # "this student has submitted; grade it": Canvas creates the submission, leaves
  # it ungraded, and puts it in the needs-grading queue.
  #
  # Also non-destructive by construction, which matters because this can re-post:
  # with no scoreGiven, Canvas skips grade submission entirely, so a grade the
  # instructor has already entered survives. What a re-post CAN disturb is the
  # needs-grading state, which is why the signature dedup below is load-bearing
  # rather than merely an optimization.
  def post_for_grading(context, line_item, progress)
    @service.post_score(
      lineitem_id: line_item.lineitem_id,
      user_lti_id: context.user_lti_id,
      comment: with_origin(progress.comment),
      activity_progress: 'Submitted',
      grading_progress: 'PendingManual',
      submission_url: (submission_launch_url(line_item) if first_push?(line_item, context))
    )
  end

  # Whether this is the first thing we've ever reported for this (column, student).
  # The submission extension rides along only then: Canvas stores the submission
  # URL only when the score claims a new submission, and a new submission is a new
  # attempt — so sending it every time would pile up attempts and push an
  # already-graded submission back into the needs-grading queue. Once is enough;
  # the URL persists on that attempt.
  def first_push?(line_item, context)
    !LtiScoreSignature.exists?(lti_line_item_id: line_item.id, lti_context_id: context.id)
  end

  # The URL Canvas stores as the submission's own, so opening a student's
  # submission launches us instead of showing Canvas's "No Preview Available".
  # Carries the column's resource marker and a `submission` flag — and no
  # identifier for the student, deliberately: this URL is persisted inside Canvas,
  # where a Wikipedia username must not go (the same rule that keeps sandbox URLs
  # out of score comments). The launch itself says who is looking.
  #
  # Only the instructor-graded columns get one; nothing grades the mechanical ones
  # by hand, so there is no submission to open.
  def submission_launch_url(line_item)
    return if ENV['LTIAAS_DOMAIN'].blank?

    "https://#{ENV['LTIAAS_DOMAIN']}/lti/launch" \
      "?resource=#{CGI.escape(line_item.resource_marker)}&submission=1"
  end

  # AGS carries the state of the activity next to the score, and the platform is
  # entitled to act on it — an activity reported `Completed` is finished work as
  # far as Canvas is concerned. The trainings roll-up legitimately pushes
  # fractions (1 of 4 modules done is 0.25), so the blanket `Completed` this
  # replaces contradicted the score it travelled with. `gradingProgress` stays
  # FullyGraded in both cases: what the student has done so far is fully graded,
  # nothing is pending on our side. Instructor-graded columns don't come through
  # here at all — see #post_for_grading.
  def activity_progress(progress)
    progress.score_given.to_f < progress.score_maximum.to_f ? 'InProgress' : 'Completed'
  end

  # Append the Dashboard's origin to a score comment so Canvas's authorless
  # "- Someone" attribution (its Score API can't set the comment author) reads
  # less mysteriously. Blank comments (most progress types emit none) stay
  # blank — we don't post a bare attribution with no other content.
  def with_origin(comment)
    return comment if comment.blank? || ENV['dashboard_url'].blank?

    "#{comment} — #{ENV['dashboard_url']}"
  end

  def signature_unchanged?(line_item, context, signature)
    LtiScoreSignature.exists?(lti_line_item_id: line_item.id, lti_context_id: context.id,
                              signature:)
  end

  def record_signature(line_item, context, signature)
    row = LtiScoreSignature.find_or_initialize_by(
      lti_line_item_id: line_item.id, lti_context_id: context.id
    )
    row.signature = signature
    row.last_pushed_at = Time.current
    row.save!
  end

  def compute_progress(line_item, context)
    LtiGradableProgress.for(line_item:, context:, course: @binding.course)
  end
end
