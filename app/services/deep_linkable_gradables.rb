# frozen_string_literal: true

# The set of gradables an instructor can attach to Canvas assignments via the
# LTI deep-linking picker: the "Wikipedia account" setup indicator (always),
# the rolled-up "Wikipedia trainings" option (when the course has any training
# modules), and one option per *exercise* Block in the course timeline. Each
# option's `resource` key is the marker we send to Canvas (and read back off
# the launch) to bind the created line item to its Dashboard gradable.
#
# This list is also what `SyncLtiLineItems` discovery matches Canvas columns
# against (by tag == resource), so the picker's offer and the sync's
# reconciliation can't drift apart.
# Gradables carry no description: the created Canvas assignments launch the
# tool, and the launched iframe presents the descriptive content live from
# the Dashboard (so it can't go stale the way baked-in text would).
class DeepLinkableGradables
  Gradable = Struct.new(:resource, :gradable_type, :gradable_id, :label, keyword_init: true)

  # User-facing Canvas gradebook column names — operator-supplied.
  TRAININGS_LABEL = 'Wikipedia trainings'
  SETUP_LABEL = 'Wikipedia account'

  attr_reader :result

  def initialize(course)
    @course = course
    @result = perform
  end

  private

  def perform
    options = exercise_blocks.map { |block| gradable_for_block(block) }
    options.unshift(trainings_rollup) if any_trainings?
    options.unshift(setup_indicator)
    options
  end

  def setup_indicator
    Gradable.new(resource: LtiLineItem::SETUP_TYPE,
                 gradable_type: LtiLineItem::SETUP_TYPE,
                 gradable_id: nil, label: SETUP_LABEL)
  end

  def gradable_for_block(block)
    Gradable.new(resource: "Block:#{block.id}", gradable_type: 'Block',
                 gradable_id: block.id, label: label_for_block(block))
  end

  def trainings_rollup
    Gradable.new(resource: LtiLineItem::TRAINING_PROGRESS_TYPE,
                 gradable_type: LtiLineItem::TRAINING_PROGRESS_TYPE,
                 gradable_id: nil, label: TRAININGS_LABEL)
  end

  # In timeline order (week, then block position) so the picker mirrors
  # the timeline rather than row-insertion order.
  def gradable_blocks
    @gradable_blocks ||=
      @course.blocks.includes(:week).to_a
             .select { |b| b.training_module_ids.any? }
             .sort_by { |b| [b.week.order, b.order] }
  end

  def exercise_blocks
    gradable_blocks.select { |b| b.training_modules.any?(&:exercise?) }
  end

  def any_trainings?
    gradable_blocks.any? do |b|
      b.training_modules.any? { |m| m.kind == TrainingModule::Kinds::TRAINING }
    end
  end

  def label_for_block(block)
    LtiGradebookLabel.for_block(block)
  end
end
