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
class SyncLtiGrades
  attr_reader :binding

  def initialize(binding)
    @binding = binding
    perform
  end

  private

  def perform
    return if @binding.course.nil?
    return if @binding.ltiaas_service_credentials.blank?

    SyncLtiLineItems.new(@binding) # bring line-item set up to date first
    @service = LtiServiceSession.new(@binding)
    push_scores_for_each_student
    @binding.update!(last_grade_sync_at: Time.current)
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

  # All non-staff members (linked or not); instructors excluded via LMS roles.
  def student_contexts
    @binding.lti_contexts.reject(&:instructor?)
  end

  def linked_student_contexts
    @binding.linked_student_contexts
  end

  def active_line_items
    LtiLineItem.where(lti_course_binding_id: @binding.id, archived_at: nil)
  end

  # LTIAAS/Canvas 422 when the target user isn't a gradable student in the
  # course (removed from the roster, or not a student). Expected and handled,
  # not an error to report — otherwise a stale membership floods Sentry on
  # every 30-min cycle.
  MEMBERSHIP_GONE = /not found in (?:the )?course|not a student/i

  def push_one(context, line_item)
    progress = compute_progress(line_item, context)
    return unless progress&.gradable?
    return if skip_zero?(progress, line_item, context)
    return if signature_unchanged?(line_item, context, progress.signature)

    post_score(context, line_item, progress)
    record_signature(line_item, context, progress.signature)
  rescue LtiaasClient::LtiaasClientError => e
    return log_non_gradable(context, line_item) if membership_gone?(e)

    report_push_failure(e, context, line_item)
  rescue StandardError => e
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
  # "Wikipedia account" roster. A zero still posts if we've previously recorded
  # a score for this pair (a genuine correction downward, e.g. un-completion).
  def skip_zero?(progress, line_item, context)
    progress.score_given.to_f.zero? &&
      !LtiScoreSignature.exists?(lti_line_item_id: line_item.id, lti_context_id: context.id)
  end

  def post_score(context, line_item, progress)
    @service.post_score(
      lineitem_id: line_item.lineitem_id,
      user_lti_id: context.user_lti_id,
      score_given: progress.score_given,
      score_maximum: progress.score_maximum,
      comment: progress.comment
    )
  end

  def signature_unchanged?(line_item, context, signature)
    LtiScoreSignature.where(lti_line_item_id: line_item.id,
                            lti_context_id: context.id,
                            signature:).exists?
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
    case line_item.gradable_type
    when LtiLineItem::SETUP_TYPE
      LtiSetupProgress.new(context)
    when LtiLineItem::TRAINING_PROGRESS_TYPE
      LtiTrainingProgress.new(@binding.course, context.user)
    when 'Block'
      block = Block.find_by(id: line_item.gradable_id)
      block && LtiBlockProgress.new(block, context.user,
                                    exercises_only: @binding.rolled_up_trainings?)
    end
  end
end
