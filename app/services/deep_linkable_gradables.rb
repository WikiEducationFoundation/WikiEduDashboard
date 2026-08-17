# frozen_string_literal: true

# The set of gradables an instructor can attach to Canvas assignments via the
# LTI deep-linking picker: the "Wikipedia account" setup indicator (always), the
# rolled-up "Wikipedia trainings" option (when the course has any training
# modules), one option per *exercise* Block in the course timeline, and the
# peer-review stage (when the course expects reviews). Each option's `resource`
# key is the marker we send to Canvas (and read back off the launch) to bind the
# created line item to its Dashboard gradable.
#
# Order is load-bearing twice over: it's the order the picker lists, and the order
# Canvas creates the assignments in when the Modules bulk flow imports them. The
# two roll-up columns come first because they cover the whole course; everything
# else follows the timeline.
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
  PEER_REVIEW_LABEL = 'Wikipedia peer review'

  # How the peer-review stage is identified on the timeline: by block title. The
  # wizard writes "Peer review an article" / "…two articles" / "…three articles"
  # for the work itself and "Peer reviews are complete" for the milestone closing
  # the stage — and none of those blocks carries a training module, peer review
  # having neither an exercise nor an assigned training.
  #
  # An earlier version of this looked for a `peer-review` training module and
  # found nothing on any real timeline, so the column silently lost its due date
  # and sorted to the end of the picker (found in the 2026-08-04 walkthrough;
  # title-matching confirmed by the operator as the intended signal).
  #
  # Anchored at the start on purpose: "Respond to your peer review" is a separate,
  # later block and must not be mistaken for the stage's end.
  PEER_REVIEW_TITLE = /\Apeer review/i

  attr_reader :result

  def initialize(course)
    @course = course
    @result = perform
  end

  private

  def perform
    options = timeline_gradables
    options.unshift(trainings_rollup) if any_trainings?
    options.unshift(setup_indicator)
    options
  end

  # The timeline's own stages, in timeline order. Peer review used to be appended
  # after the exercises, which read as the final assignment of the course rather
  # than the mid-term stage it usually is — and the picker's order is also the
  # order Canvas creates the assignments in, so it misordered the module too.
  #
  # The two roll-up columns stay pinned in front (see #perform): they cover the
  # whole course rather than sitting at a point in it.
  def timeline_gradables
    items = exercise_blocks.map { |block| [timeline_position(block), gradable_for_block(block)] }
    items << [peer_review_position, peer_review_stage] if peer_reviews_expected?
    items.sort_by(&:first).map(&:last)
  end

  def timeline_position(block)
    [block.week.order, block.order]
  end

  # A course can expect peer reviews without its timeline mentioning them, in
  # which case there is no position to sort into and the stage goes last — the
  # same place it used to go unconditionally.
  def peer_review_position
    peer_review_block ? timeline_position(peer_review_block) : [Float::INFINITY, 0]
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

  # The LAST peer-review block by timeline position. The stage spans a couple of
  # blocks — the reviewing itself, then the milestone that closes it — and what
  # the column's deadline means is "your reviews are done by here", so the end of
  # the stage is the date to carry. Deterministic by position rather than by
  # whatever order the rows come back in.
  #
  # nil when the course expects reviews but no block is titled for them (an
  # instructor who retitled the block, or a hand-built timeline): the column is
  # still offered, just without a date, and sorts last.
  def peer_review_block
    @peer_review_block ||= @course.blocks.includes(:week).to_a
                                  .select { |block| block.title.to_s.match?(PEER_REVIEW_TITLE) }
                                  .max_by { |block| timeline_position(block) }
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
