# frozen_string_literal: true

# Pushes LTIAAS AGS scores for every linked student × active line item in
# one LtiCourseBinding. v1 re-posts every cycle without deduplication;
# the LtiLineItem.last_pushed_signature column is reserved for a future
# per-student-per-line-item dedup optimization.
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
    linked_contexts.find_each do |context|
      active_line_items.each do |line_item|
        push_one(context, line_item)
      end
    end
  end

  def linked_contexts
    LtiContext.where(lti_course_binding_id: @binding.id).where.not(user_id: nil)
  end

  def active_line_items
    LtiLineItem.where(lti_course_binding_id: @binding.id, archived_at: nil)
  end

  def push_one(context, line_item)
    progress = compute_progress(line_item, context.user)
    return unless progress&.gradable?

    @service.post_score(
      lineitem_id: line_item.lineitem_id,
      user_lti_id: context.user_lti_id,
      score_given: progress.score_given,
      score_maximum: progress.score_maximum,
      comment: progress.comment
    )
  rescue StandardError => e
    Sentry.capture_exception(
      e,
      extra: { binding_id: @binding.id, user_lti_id: context.user_lti_id,
               lineitem_id: line_item.lineitem_id }
    )
  end

  def compute_progress(line_item, user)
    case line_item.gradable_type
    when LtiLineItem::TRAINING_PROGRESS_TYPE
      LtiTrainingProgress.new(@binding.course, user)
    when 'Block'
      block = Block.find_by(id: line_item.gradable_id)
      block && LtiBlockProgress.new(block, user, exercises_only: @binding.lumped?)
    end
  end
end
