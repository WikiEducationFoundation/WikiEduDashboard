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
#
# They DO carry a due date, which is a deliberately different call (operator
# decision 2026-08-03). A date baked into a Canvas assignment can go stale the
# same way a description would — the Dashboard timeline is the authority and
# nothing pushes a correction after import — but without one Canvas has no
# deadline to put in the student's Calendar or To Do list, which is most of what
# an imported assignment is for. Timelines are rarely rearranged after import,
# and an instructor can edit a date in Canvas; a missing deadline is not
# something they can fix at all. The policy per gradable:
#
#   - Exercise blocks take their block's due date (explicit, or the end of the
#     block's week — see BlockDateManager).
#   - The trainings roll-up takes the LAST training block's due date: the column
#     is complete only when every training is, so the last one sets the deadline.
#   - The "Wikipedia account" indicator takes none. It reports a state a student
#     reaches once and keeps, not work due by a date, and a deadline on it would
#     mark students late for something they can't do twice.
class DeepLinkableGradables
  Gradable = Struct.new(:resource, :gradable_type, :gradable_id, :label, :due_date,
                        keyword_init: true)

  # User-facing Canvas gradebook column names — operator-supplied.
  TRAININGS_LABEL = 'Wikipedia trainings'
  SETUP_LABEL = 'Wikipedia account'
  # [PLACEHOLDER - gradebook column name for the peer review stage]
  PEER_REVIEW_LABEL = 'Wikipedia peer review'

  # The training module that marks the peer-review stage on the timeline. Peer
  # review has no exercise, so the block holding this training is what gives the
  # column its due date.
  PEER_REVIEW_MODULE_SLUG = 'peer-review'

  attr_reader :result

  def initialize(course)
    @course = course
    @result = perform
  end

  private

  def perform
    options = exercise_blocks.map { |block| gradable_for_block(block) }
    options << peer_review_stage if peer_reviews_expected?
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
                 gradable_id: block.id, label: label_for_block(block),
                 due_date: block.calculated_due_date)
  end

  def trainings_rollup
    Gradable.new(resource: LtiLineItem::TRAINING_PROGRESS_TYPE,
                 gradable_type: LtiLineItem::TRAINING_PROGRESS_TYPE,
                 gradable_id: nil, label: TRAININGS_LABEL,
                 due_date: last_training_due_date)
  end

  # Every training has to be done for the roll-up to be complete, so the last
  # one's deadline is the column's. Nil if none of the training blocks yields a
  # date, rather than a guess.
  def last_training_due_date
    training_blocks.filter_map(&:calculated_due_date).max
  end

  # The peer-review stage as its own column. Offered on the strength of the
  # course's expected-review count rather than a timeline block, because that
  # setting is what says the stage is part of the course; the block is only where
  # the due date comes from, and a course can expect reviews with the block
  # retitled or moved.
  def peer_review_stage
    Gradable.new(resource: LtiLineItem::PEER_REVIEW_TYPE,
                 gradable_type: LtiLineItem::PEER_REVIEW_TYPE,
                 gradable_id: nil, label: PEER_REVIEW_LABEL,
                 due_date: peer_review_block&.calculated_due_date)
  end

  def peer_reviews_expected?
    @course.peer_review_count.to_i.positive?
  end

  # Peer review's own timeline block: the one holding the peer-review training.
  # nil when the course expects reviews but its timeline never mentions them, in
  # which case the column simply carries no due date.
  def peer_review_block
    @peer_review_block ||= @course.blocks.includes(:week).to_a.find do |block|
      block.training_modules.any? { |mod| mod.slug == PEER_REVIEW_MODULE_SLUG }
    end
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

  # The blocks the trainings roll-up covers — training-kind modules only, the
  # same set LtiTrainingProgress scores. Exercises have their own columns.
  def training_blocks
    gradable_blocks.select do |b|
      b.training_modules.any? { |m| m.kind == TrainingModule::Kinds::TRAINING }
    end
  end

  def any_trainings?
    training_blocks.any?
  end

  def label_for_block(block)
    LtiGradebookLabel.for_block(block)
  end
end
