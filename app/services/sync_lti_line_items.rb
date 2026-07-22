# frozen_string_literal: true

# Reconciles LTIAAS gradebook line items for one LtiCourseBinding against
# the bound Dashboard course's timeline.
#
# Granularity controls the desired line-item set
# (LtiCourseBinding#gradebook_granularity):
#   - 'standard' (default): one rolled-up `TrainingProgress` line item for all
#     training-kind module progress, plus one line item per exercise Block,
#     plus the setup ("Wikipedia account") indicator.
#   - 'per_block': the setup indicator plus one line item per Block that has
#     any training_module_ids (no roll-up; trainings grade through their own
#     block's column).
#   - 'lumped' (deep-link-first): NOTHING is auto-created — the instructor
#     imports the columns they want (setup indicator, trainings roll-up,
#     exercises) via the deep-linking picker. This service instead DISCOVERS
#     those columns (matched by tag == the gradable's resource marker) and
#     binds local rows, so grade sync reaches them without waiting for each
#     column to be launched.
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
    kept = desired.map { |type, id, _| [type, id] }
    kept += discover_deep_linked_columns(existing) if @binding.lumped?
    archive_stale(existing, kept)
  end

  def desired_line_items
    # Deep-link-first mode: the instructor imports every column via the
    # picker; nothing is created behind their back.
    return [] if @binding.lumped?

    # The setup ("connected a Wikipedia account") column exists on every
    # auto-creating binding, independent of the timeline.
    setup = [[LtiLineItem::SETUP_TYPE, nil, setup_label]]
    setup + trainings_rollup_desired + block_columns_desired
  end

  def trainings_rollup_desired
    return [] unless @binding.rolled_up_trainings? && any_trainings?

    [[LtiLineItem::TRAINING_PROGRESS_TYPE, nil, trainings_rollup_label]]
  end

  # Which blocks get their own auto-created column: every gradable block in
  # per_block mode, just the exercise blocks in standard mode (trainings live
  # in the roll-up).
  def block_columns_desired
    blocks = @binding.per_block? ? gradable_blocks : exercise_blocks
    blocks.map { |block| ['Block', block.id, label_for_block(block)] }
  end

  # In deep-link-first mode instructors create every column via the picker;
  # we don't. Find the ones that exist in Canvas — each is tagged with its
  # gradable's resource marker — and bind a local row (creating or reviving)
  # so grade sync + the roster resolve to them. Returns the bound gradable
  # keys so archive_stale keeps them (they aren't in `desired`).
  def discover_deep_linked_columns(existing)
    by_tag = @service.list_line_items.index_by { |item| item['tag'] }
    DeepLinkableGradables.new(@binding.course).result.filter_map do |gradable|
      canvas_item = by_tag[gradable.resource]
      next unless canvas_item

      bind_discovered_line_item(gradable, canvas_item, existing)
      [gradable.gradable_type, gradable.gradable_id]
    end
  end

  def bind_discovered_line_item(gradable, canvas_item, existing)
    line_item = existing[[gradable.gradable_type, gradable.gradable_id]] ||
                LtiLineItem.new(lti_course_binding: @binding,
                                gradable_type: gradable.gradable_type,
                                gradable_id: gradable.gradable_id)
    line_item.update!(lineitem_id: canvas_item['id'],
                      label: gradable.label, archived_at: nil)
  end

  # In timeline order (week, then block position): Canvas lists assignments
  # in creation order, so creating them in timeline order is what makes the
  # Assignments tab mirror the timeline.
  def gradable_blocks
    @gradable_blocks ||=
      @binding.course.blocks
              .includes(:week)
              .to_a
              .select { |b| b.training_module_ids.any? }
              .sort_by { |b| [b.week.order, b.order] }
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
    LtiGradebookLabel.for_block(block)
  end

  def trainings_rollup_label
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
    # need a resourceLinkId for any of our operations. launch_url makes
    # the Canvas assignment launch the tool (Canvas submission_type
    # extension) so students/instructors get the drill-down views.
    lineitem_id = @service.upsert_line_item(
      label:,
      tag: tag_for(gradable_type, gradable_id),
      launch_url: "https://#{ENV['LTIAAS_DOMAIN']}/lti/launch"
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

  def archive_stale(existing, kept_keys)
    kept = kept_keys.to_set
    existing.each_value do |line_item|
      key = [line_item.gradable_type, line_item.gradable_id]
      next if kept.include?(key) || line_item.archived?

      line_item.archive!
    end
  end

  def tag_for(gradable_type, gradable_id)
    gradable_id.nil? ? gradable_type : "#{gradable_type}:#{gradable_id}"
  end
end
