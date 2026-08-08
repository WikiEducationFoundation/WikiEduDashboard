# frozen_string_literal: true

# Records whether Canvas has been handed a submission launch URL for a
# (column, student) pair.
#
# The sync previously inferred this from "no signature row yet", which meant any
# pair already syncing before the submission extension shipped could never get a
# URL — permanently "No Preview Available" for every course mid-term. Nullable
# with no default: existing rows read as never-reported, which is what they are,
# so the next sync sends them one.
class AddSubmissionReportedAtToLtiScoreSignatures < ActiveRecord::Migration[7.0]
  def change
    add_column :lti_score_signatures, :submission_reported_at, :datetime, null: true
  end
end
