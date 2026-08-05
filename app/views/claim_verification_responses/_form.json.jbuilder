# frozen_string_literal: true

# The exercise form's definition with its copy resolved for the current locale:
# the steps, their questions, and the answers each offers. The SPA renders both
# the form and the submitted-answers summary from this, so adding a question or
# reordering the steps in config/claim_verification_exercise.yml needs no
# JavaScript change. `form` is a ClaimVerification::ExerciseForm.
#
# `visible_when` is passed through as declared — the client applies it live as
# the student answers, and the server applies it again on submission.
json.steps form.steps do |step|
  json.id step.id
  json.heading step.heading
  json.instructions step.instructions
  json.visible_when step.visible_when

  json.questions step.questions do |question|
    json.call(question, :id, :type, :required, :visible_when)
    json.label question.label
    json.options question.option_labels if question.choice?
  end
end
