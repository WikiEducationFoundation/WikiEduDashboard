# frozen_string_literal: true

# A deep-link reservation may be taken by reviving an ARCHIVED line item — the
# gradable's Canvas column was deleted, so the slot is offerable again, and the
# slot's one row (the unique index on (binding, gradable_key) allows only one) is
# reused rather than duplicated. Reviving clears the archived state, which is
# fine when the import completes: discovery adopts the row and the old mapping is
# superseded.
#
# It is not fine when the reservation is abandoned. Expiry destroys a pending row
# — right for a reservation that was created from nothing, wrong for one that was
# revived, because the destroy takes the row's previous Canvas mapping and its
# score signatures with it. This column holds the revived row's prior attributes
# as JSON so expiry can put them back instead, leaving the slot exactly as the
# reservation found it. NULL on a reservation that created its own row (nothing
# to roll back to) and on every bound row.
class AddReservedPriorStateToLtiLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :lti_line_items, :reserved_prior_state, :text
  end
end
