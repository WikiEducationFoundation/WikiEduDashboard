# The result of taking a claim: the new assignment (null if the chosen claim
# could no longer be found in the article), so the SPA can transition to the
# taken-claim view without a reload.
if @assignment
  json.assignment { json.partial! 'assignment', assignment: @assignment }
else
  json.assignment nil
end
