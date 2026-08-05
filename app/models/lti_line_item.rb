# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_line_items
#
#  id                       :integer          not null, primary key
#  lti_course_binding_id    :integer          not null
#  gradable_type            :string(255)      not null
#  gradable_id              :integer
#  lineitem_id              :string(512)      - NULL while the row is a pending
#                                               deep-link reservation, filled in
#                                               once the Canvas column exists
#  label                    :string(255)
#  score_maximum            :decimal(10, 4)   default(1.0), not null
#  archived_at              :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  canvas_assignment_id     :string(255)      - Canvas-side assignment id, used
#                                               to route assignment_view launches
#                                               back to this line item; nil until
#                                               first captured/backfilled
#  reserved_prior_state     :text(65535)      - JSON snapshot of the attributes a
#                                               deep-link reservation overwrote
#                                               when it revived an archived row,
#                                               so an abandoned reservation can be
#                                               rolled back instead of destroyed;
#                                               NULL unless the row is a revived
#                                               pending reservation
#

# Maps a Dashboard gradable unit to an LTIAAS-managed LMS gradebook line
# item.
#
# `gradable_type='Block'` maps one timeline block's exercise column, created
# when the instructor imports it via deep linking.
# `gradable_type='TrainingProgress'` is a sentinel for the rolled-up trainings
# column; `gradable_id` is null in that case. `gradable_type='WikipediaSetup'` is a
# sentinel (also `gradable_id` null) for the per-student "connected a Wikipedia
# account" indicator column — see LtiSetupProgress; it exists on every bound
# course regardless of timeline, and unlike the others is posted for *every*
# discovered student (1.0 once linked; a not-yet-connected student is left
# ungraded rather than given a failing 0 — see SyncLtiGrades#skip_zero?).
#
# We never destroy LTIAAS-side line items (it would erase Canvas gradebook
# columns and student grades). When the Dashboard timeline drops a block,
# we set `archived_at` and stop pushing scores to the orphaned line item.
#
# A row with a NULL `lineitem_id` is a PENDING reservation: the deep-link
# picker creates it before returning the self-submitting form to Canvas, so a
# double-submitted or replayed picker POST in the window before discovery
# binds the real column hits the (binding, gradable_key) unique index instead
# of minting a duplicate Canvas assignment. SyncLtiLineItems adopts the row
# (fills lineitem_id) when the column appears, and expires it if the form
# never reached Canvas. Pending rows are not live AGS columns — anything that
# posts scores or reports imported assignments must use the `bound` scope.
#
# A reservation that was taken by REVIVING an archived row carries the archived
# attributes it overwrote in `reserved_prior_state`, so expiry restores them
# rather than destroying a row that predates the reservation (see
# #expire_reservation!). Adoption clears the snapshot: once the column exists,
# the prior mapping is superseded and there is nothing to roll back to.
class LtiLineItem < ApplicationRecord
  TRAINING_PROGRESS_TYPE = 'TrainingProgress'
  SETUP_TYPE = 'WikipediaSetup'
  # The peer-review stage. A sentinel like the two above (`gradable_id` null)
  # because peer review has no exercise module to hang a Block off — what it has
  # is a dated timeline block and a course setting for how many reviews are
  # expected. See LtiPeerReviewProgress.
  PEER_REVIEW_TYPE = 'PeerReview'

  belongs_to :lti_course_binding
  belongs_to :gradable, polymorphic: true, optional: true
  has_many :lti_score_signatures, dependent: :destroy

  # A stored signature means "we already pushed this exact score to this column".
  # `lineitem_id` is mutable — an instructor who deletes an imported Canvas
  # assignment and re-imports it gets a new Canvas line item, and both
  # SyncLtiLineItems#bind_discovered_line_item and
  # ResolveAssignmentLineItem#bind_line_item repoint this row at it rather than
  # creating another. The signatures are keyed on this row's id, so they survived
  # that repoint and described a column that no longer exists: grade sync's
  # `signature_unchanged?` matched, the push was skipped, and the new gradebook
  # column stayed blank with no error and no Sentry event. Because zeros are never
  # seeded either, it wouldn't necessarily self-heal.
  after_update :discard_score_signatures, if: :saved_change_to_lineitem_id?

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :pending, -> { where(lineitem_id: nil) }
  scope :bound, -> { where.not(lineitem_id: nil) }

  validates :gradable_type, presence: true
  validates :score_maximum, numericality: { greater_than: 0 }
  # One line item per (binding, gradable). Enforced in the database by the unique
  # index on (lti_course_binding_id, gradable_key) — `gradable_key` is a stored
  # generated column that folds the sentinels' null gradable_id into a non-null
  # string, because MySQL exempts NULLs from unique indexes. This validation
  # exists on top of it only to turn the race's loser into a handleable error
  # instead of a bare RecordNotUnique.
  validates :gradable_id, uniqueness: { scope: %i[lti_course_binding_id gradable_type] }

  # Sentinel columns the Dashboard can grade by itself: an account is connected
  # or it isn't, a training module is completed or it isn't. Everything else is
  # student work whose quality only the instructor can assess — the exercise
  # Blocks, and peer review, where the Dashboard can see that a review page was
  # written but not whether the review is any good. Those report submission and
  # leave the grade to the instructor (see LtiScorePayload#for_grading).
  #
  # Keyed on gradable_type rather than a per-block flag: nothing to keep in step
  # with the timeline, and a new sentinel column has to pick a side explicitly.
  MECHANICAL_TYPES = [SETUP_TYPE, TRAINING_PROGRESS_TYPE].freeze

  def instructor_graded?
    MECHANICAL_TYPES.exclude?(gradable_type)
  end

  # This column's deep-link resource marker: the string DeepLinkableGradables
  # offers, Canvas carries as the line item's tag, and SyncLtiLineItems matches on
  # — "Block:12" for a timeline block, the bare type for a sentinel column. NOT
  # `gradable_key`, the generated column behind the unique index, which folds a
  # null gradable_id into a trailing colon.
  def resource_marker
    gradable_id ? "#{gradable_type}:#{gradable_id}" : gradable_type
  end

  def archived?
    archived_at.present?
  end

  def pending?
    lineitem_id.nil?
  end

  # Ends this abandoned reservation — but only after re-checking the row under a
  # lock. Between a sync loading the row and deciding to expire it, a launch or
  # another sync can adopt it; an unconditional write would then clobber a live,
  # bound column mapping and reopen the gradable to a duplicate import.
  # `with_lock` reloads, so the check runs against the current row.
  #
  # A reservation that created its own row is destroyed: nothing preceded it, and
  # a row that was never bound has no score signatures to lose. A revived one is
  # rolled back to the archived state it overwrote instead — destroying it would
  # throw away a mapping and signature history that predate the reservation, for
  # a column that may well still exist in Canvas.
  def expire_reservation!(older_than:)
    with_lock do
      next unless pending? && updated_at < older_than

      prior = reserved_prior_attributes
      prior ? restore_prior_state!(prior) : destroy!
    end
  rescue ActiveRecord::RecordNotFound
    nil # a concurrent sync already expired it
  end

  # The attributes a reservation overwrote to revive this row, or nil if it
  # created the row (see ReserveLtiLineItems).
  def reserved_prior_attributes
    return if reserved_prior_state.blank?

    JSON.parse(reserved_prior_state)
  rescue JSON::ParserError
    nil
  end

  def archive!
    update!(archived_at: Time.current) unless archived?
  end

  private

  # update_columns, not update!: putting back the row's own previous
  # `lineitem_id` is exactly the case where the signature-discard callback must
  # NOT fire — those signatures describe the column being restored, and
  # discarding them would re-push every score if that column is bound again.
  # (The revival that overwrote these attributes skipped the callback for the
  # same reason.) updated_at is bumped by hand for the same skipped-callback
  # reason, so the row's archived state carries the time it was rolled back.
  def restore_prior_state!(prior)
    update_columns(prior.slice('archived_at', 'lineitem_id', 'canvas_assignment_id', 'label')
                        .merge('reserved_prior_state' => nil, 'updated_at' => Time.current))
  end

  def discard_score_signatures
    LtiScoreSignature.where(lti_line_item_id: id).delete_all
  end
end
