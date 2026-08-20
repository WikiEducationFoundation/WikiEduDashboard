# frozen_string_literal: true

# Reserves the deep-link picker's chosen gradables with pending LtiLineItem
# rows (lineitem_id NULL) before the self-submitting form is returned to
# Canvas. The real column's local row only lands minutes later — discovery by
# tag (SyncLtiLineItems) or a launch-time bind — so without a reservation a
# double-submitted or replayed picker POST inside that window passes the
# offerable check again and Canvas mints a second assignment with the same
# tag; the (binding, gradable_key) unique index then leaves the duplicate
# column stranded with no local row. SyncLtiLineItems adopts the pending row
# once the column appears, and destroys it if the form never reached Canvas.
#
# All-or-nothing: any slot already held (an active row, pending or bound)
# rolls the whole reservation back and `reserved` is false — the caller
# refuses the submission the same way it refuses a tampered selection.
class ReserveLtiLineItems
  attr_reader :reserved

  def initialize(binding:, gradables:)
    @binding = binding
    @gradables = gradables
    @created_ids = []
    @revived = {}
    @reserved = perform
  end

  # Rolls this reservation back when the caller can't finish the flow — the
  # form never reached Canvas, so without this the gradables stay squatted
  # for the whole pending lease (and the discovery job that would eventually
  # clean them up may never have been scheduled). Fresh rows are deleted;
  # a revived row goes back to the archived state it had before the
  # reservation, keeping its historical mapping and score signatures. Both
  # statements are conditioned on the row still being pending — the
  # single-statement equivalent of the locked re-check expiry uses — so a
  # row adopted in the meantime is a live column mapping and stays.
  #
  # This is the in-request path only. A reservation whose form response WAS
  # returned but which Canvas never acted on is rolled back by expiry instead,
  # off the same snapshot persisted in `reserved_prior_state` — see
  # LtiLineItem#expire_reservation!.
  def release
    LtiLineItem.pending.where(id: @created_ids).delete_all
    @revived.each do |id, prior|
      LtiLineItem.pending.where(id:)
                 .update_all(prior.merge('reserved_prior_state' => nil,
                                         'updated_at' => Time.current))
    end
  end

  private

  def perform
    LtiLineItem.transaction do
      @gradables.all? { |gradable| reserve(gradable) } || raise(ActiveRecord::Rollback)
    end || false
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, ActiveRecord::Deadlocked
    false
  end

  # A fresh slot gets a new pending row; the losing side of a concurrent
  # create hits the model's uniqueness validation or the unique index. A slot
  # holding an archived row (its Canvas column was deleted, so the gradable is
  # offerable again) is re-used instead — a plain create would collide with
  # the archived row in the index and 422 every re-import.
  def reserve(gradable)
    row = LtiLineItem.find_by(lti_course_binding_id: @binding.id,
                              gradable_type: gradable.gradable_type,
                              gradable_id: gradable.gradable_id)
    row.nil? ? create_pending(gradable) : revive_as_pending(row, gradable)
  end

  def create_pending(gradable)
    row = LtiLineItem.create!(lti_course_binding_id: @binding.id,
                              gradable_type: gradable.gradable_type,
                              gradable_id: gradable.gradable_id,
                              label: gradable.label)
    @created_ids << row.id
    true
  end

  # Compare-and-swap on archived_at, so of two concurrent revivals only one
  # can win — the loser's UPDATE matches zero rows once the winner commits.
  # An active row (someone else's reservation or a bound column) never
  # matches, so it reads as a lost race too. update_all skips the
  # signature-discard callback; the stale signatures from the row's previous
  # column are discarded when adoption fills the new lineitem_id (see
  # LtiLineItem#discard_score_signatures).
  # The prior attributes are snapshotted from the row as loaded; if this CAS
  # wins, the row was archived (and so quiescent) between that load and now,
  # which is what makes the snapshot safe to restore from in #release.
  #
  # The snapshot is also written to the row itself, because #release only covers
  # failures inside this request. When the form response succeeds and Canvas
  # never creates the assignment, the rollback happens minutes later in a sync
  # process that has nothing but the row — and without the persisted snapshot
  # that path destroyed the archived mapping and its signatures. Adoption clears
  # the column (SyncLtiLineItems, ResolveAssignmentLineItem): once a real column
  # is bound there is no prior state to return to.
  def revive_as_pending(row, gradable)
    prior = row.slice('archived_at', 'lineitem_id', 'canvas_assignment_id', 'label')
    won = LtiLineItem.where(id: row.id).where.not(archived_at: nil)
                     .update_all(archived_at: nil, lineitem_id: nil, canvas_assignment_id: nil,
                                 label: gradable.label, reserved_prior_state: prior.to_json,
                                 updated_at: Time.current) == 1
    @revived[row.id] = prior if won
    won
  end
end
