# The student's taken claim, for the SPA's taken-claim view (where the
# verification form lives). `assignment` is a VerificationClaimAssignment.
json.claim do
  json.partial! 'claim_verification_exercises/claim', claim: assignment.verification_claim
end
