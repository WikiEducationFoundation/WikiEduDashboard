# frozen_string_literal: true

# Reconciles LTIAAS gradebook line items for one LtiCourseBinding against
# the bound Dashboard course's timeline.
#
# Granularity controls the desired line-item set
# (LtiCourseBinding#gradebook_granularity):
#   - 'lumped' (default): one rolled-up `TrainingProgress` line item for
#     all training-kind module progress, plus one line item per *exercise*
#     block (a Block whose training_module_ids include any kind=1 module).
#   - 'per_block': one line item per Block that has any training_module_ids.
#
# v1 line-item lifecycle:
#   - Create on first sync where the gradable is missing locally.
#   - Update label via PUT when it has changed.
#   - Soft-archive locally (set archived_at) for line items whose gradable
#     went away in the timeline. We never DELETE from LTIAAS — that would
#     erase the corresponding Canvas gradebook column and its scores.
#
# A binding without a stored serviceKey is a no-op (we haven't seen a
# launch from this Canvas course yet).
class SyncLtiLineItems
  attr_reader :binding

  def initialize(binding)
    @binding = binding
    perform
  end

  private

  def perform
    return if @binding.course.nil?
    return if @binding.ltiaas_service_credentials.blank?

    @service = LtiServiceSession.new(@binding)
    desired = desired_line_items
    existing = LtiLineItem.where(lti_course_binding_id: @binding.id)
                          .index_by { |li| [li.gradable_type, li.gradable_id] }

    desired.each do |gradable_type, gradable_id, label|
      reconcile(gradable_type, gradable_id, label, existing)
    end
    archive_stale(existing, desired)
  end

  def desired_line_items
    # The setup ("connected a Wikipedia account") column exists on every bound
    # course, independent of the timeline and granularity.
    setup = [[LtiLineItem::SETUP_TYPE, nil, setup_label]]
    setup + (@binding.lumped? ? lumped_desired : per_block_desired)
  end

  def lumped_desired
    desired = []
    desired << [LtiLineItem::TRAINING_PROGRESS_TYPE, nil, lumped_training_label] if any_trainings?
    exercise_blocks.each do |block|
      desired << ['Block', block.id, label_for_block(block)]
    end
    desired
  end

  def per_block_desired
    gradable_blocks.map do |block|
      ['Block', block.id, label_for_block(block)]
    end
  end

  def gradable_blocks
    @gradable_blocks ||=
      @binding.course.blocks
              .includes(:week)
              .to_a
              .select { |b| b.training_module_ids.any? }
  end

  def exercise_blocks
    gradable_blocks.select { |b| block_has_exercise?(b) }
  end

  def any_trainings?
    gradable_blocks.any? { |b| block_has_training?(b) }
  end

  def block_has_exercise?(block)
    block.training_modules.any?(&:exercise?)
  end

  def block_has_training?(block)
    block.training_modules.any? { |m| m.kind == TrainingModule::Kinds::TRAINING }
  end

  def label_for_block(block)
    week_order = block.week&.order
    prefix = week_order ? "Wk#{week_order} " : ''
    "#{prefix}#{block.title}".byteslice(0, 64)
  end

  def lumped_training_label
    'Wikipedia trainings'
  end

  # User-facing Canvas gradebook column name — operator-supplied.
  def setup_label
    'Wikipedia account'
  end

  def reconcile(gradable_type, gradable_id, label, existing)
    line_item = existing[[gradable_type, gradable_id]]
    if line_item.nil?
      create_line_item(gradable_type, gradable_id, label)
    else
      revive_or_relabel(line_item, label)
    end
  end

  def create_line_item(gradable_type, gradable_id, label)
    # Create as a course-level line item (no resourceLinkId). Canvas's
    # course-navigation placement assigns a resource_link_id that isn't
    # an AGS-eligible Lti::ResourceLink record on the platform side, so
    # passing it makes Canvas reject the create with "resource does not
    # exist" 404. The `tag` (gradable_type[:gradable_id]) is what we use
    # to identify our line items locally and via list filters; we don't
    # need a resourceLinkId for any of our operations.
    lineitem_id = @service.upsert_line_item(
      label:,
      tag: tag_for(gradable_type, gradable_id)
    )
    LtiLineItem.create!(
      lti_course_binding: @binding,
      gradable_type:, gradable_id:,
      lineitem_id:, label:
    )
  end

  def revive_or_relabel(line_item, label)
    line_item.update!(archived_at: nil) if line_item.archived?
    return if line_item.label == label

    @service.update_line_item(line_item.lineitem_id, label:,
                              score_maximum: line_item.score_maximum.to_f)
    line_item.update!(label:)
  end

  def archive_stale(existing, desired)
    desired_keys = desired.map { |type, id, _| [type, id] }.to_set
    existing.each do |key, line_item|
      next if desired_keys.include?(key)
      next if line_item.archived?

      line_item.archive!
    end
  end

  def tag_for(gradable_type, gradable_id)
    gradable_id.nil? ? gradable_type : "#{gradable_type}:#{gradable_id}"
  end
end
