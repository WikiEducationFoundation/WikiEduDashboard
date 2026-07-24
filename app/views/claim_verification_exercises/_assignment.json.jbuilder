# The student's taken claim, for the SPA's taken-claim view (where the
# verification form lives). URLs are computed by ClaimVerificationHelper.
# `assignment` is a VerificationClaimAssignment.
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
