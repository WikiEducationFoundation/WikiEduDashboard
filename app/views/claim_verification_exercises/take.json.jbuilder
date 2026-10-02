# The result of taking a claim: the new assignment (null if the chosen claim
# could no longer be found in the article), so the SPA can transition to the
# taken-claim view without a reload — plus the student's earlier response for
# this claim, if they had already submitted one for it.
if @assignment
  json.assignment { json.partial! 'assignment', assignment: @assignment }
else
  json.assignment nil
end

if @response
  json.response { json.partial! 'claim_verification_responses/response', response: @response }
else
  json.response nil
end
