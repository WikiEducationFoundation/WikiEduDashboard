# frozen_string_literal: true

# A student's verification form answers. Fields for steps that didn't apply
# (see RecordVerificationClaimResponse) are null.
json.call(response, :id, :source_access, :source_access_notes, :verdict, :claim_location,
          :verification_notes, :other_comments, :created_at, :updated_at)
