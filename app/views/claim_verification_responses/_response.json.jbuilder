# frozen_string_literal: true

# A student's verification form answers, as a hash keyed by question id. Only
# the questions the exercise actually asked them are present (see
# RecordVerificationClaimResponse), so the SPA renders the summary by walking the
# form definition and skipping whatever isn't here.
json.call(response, :id, :answers, :created_at, :updated_at)
