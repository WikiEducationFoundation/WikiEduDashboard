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
      contexts_for(line_item).find_each do |context|
        push_one(context, line_item)
      end
    end
  end

  # The setup indicator is posted for every discovered student (so the
  # instructor also sees who has NOT connected); every other line item grades
  # only students who have actually linked a Wikipedia account.
  def contexts_for(line_item)
    line_item.gradable_type == LtiLineItem::SETUP_TYPE ? all_contexts : linked_contexts
  end

  def all_contexts
    LtiContext.where(lti_course_binding_id: @binding.id)
  end

  def linked_contexts
    all_contexts.where.not(user_id: nil)
  end

  def active_line_items
    LtiLineItem.where(lti_course_binding_id: @binding.id, archived_at: nil)
  end

  def push_one(context, line_item)
    progress = compute_progress(line_item, context)
    return unless progress&.gradable?
    return if signature_unchanged?(line_item, context, progress.signature)

    post_score(context, line_item, progress)
    record_signature(line_item, context, progress.signature)
  rescue StandardError => e
    Sentry.capture_exception(
      e,
      extra: { binding_id: @binding.id, user_lti_id: context.user_lti_id,
               lineitem_id: line_item.lineitem_id }
    )
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
