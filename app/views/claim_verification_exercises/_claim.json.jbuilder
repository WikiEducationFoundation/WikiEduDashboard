# frozen_string_literal: true

# A claim as the student reads it on the taken-claim view: the sentence, the
# paragraph around it, the citation, and links to the source and to the claim in
# its article. The instructor's submissions page shows each response's claim the
# same way, so an answer can be checked against what the student saw. URLs are
# computed by ClaimVerificationHelper. `claim` is a VerificationClaim.

# Only expose the surrounding paragraph when it adds something beyond the claim.
surrounding = claim.context if claim.context.present? && claim.context != claim.sentence

json.sentence claim.sentence
json.cite_text claim.cite_text
json.context surrounding
json.source_url claim_source_url(claim)
json.article_url claim_article_url(claim)
json.article_title claim.article_title&.tr('_', ' ')
