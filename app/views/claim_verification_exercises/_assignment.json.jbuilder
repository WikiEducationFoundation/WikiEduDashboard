# The student's taken claim and the sandbox handoff, for the SPA's taken-claim
# view. URLs are computed by ClaimVerificationHelper (the same helpers the old
# HAML view used). `assignment` is a VerificationClaimAssignment.
claim = assignment.verification_claim
# Only expose the surrounding paragraph when it adds something beyond the claim.
surrounding = claim.context if claim.context.present? && claim.context != claim.sentence

json.claim do
  json.sentence claim.sentence
  json.cite_text claim.cite_text
  json.context surrounding
  json.source_url claim_source_url(claim)
  json.article_url claim_article_url(claim)
end
json.sandbox_url claim_verification_sandbox_url(@course, current_user)
