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
    @reserved = perform
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
    LtiLineItem.create!(lti_course_binding_id: @binding.id,
                        gradable_type: gradable.gradable_type,
                        gradable_id: gradable.gradable_id,
                        label: gradable.label)
    true
  end

  # Compare-and-swap on archived_at, so of two concurrent revivals only one
  # can win — the loser's UPDATE matches zero rows once the winner commits.
  # An active row (someone else's reservation or a bound column) never
  # matches, so it reads as a lost race too. update_all skips the
  # signature-discard callback; the stale signatures from the row's previous
  # column are discarded when adoption fills the new lineitem_id (see
  # LtiLineItem#discard_score_signatures).
  def revive_as_pending(row, gradable)
    LtiLineItem.where(id: row.id).where.not(archived_at: nil)
               .update_all(archived_at: nil, lineitem_id: nil, canvas_assignment_id: nil,
                           label: gradable.label, updated_at: Time.current) == 1
  end
end
