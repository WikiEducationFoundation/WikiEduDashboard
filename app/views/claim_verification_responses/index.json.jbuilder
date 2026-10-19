# frozen_string_literal: true

# All of a course's exercise activity for the instructor view: submitted
# responses first, then students who have taken a claim but not yet submitted.
# Real names come from the course enrollment records, matching how the
# students tab identifies students to instructors.
real_names = CoursesUsers.where(course: @course).pluck(:user_id, :real_name).to_h

# The questions the exercise asks, so each response's answers can be shown as
# the questions the student answered.
json.form { json.partial! 'form', form: @form }

# Each response carries its claim in full, as the student saw it, so the
# answers can be read against the citation and the source.
json.responses @responses do |response|
  json.username response.user.username
  json.real_name real_names[response.user_id]
  json.claim do
    json.partial! 'claim_verification_exercises/claim', claim: response.verification_claim
  end
  json.partial! 'response', response:
end

json.pending @pending do |assignment|
  claim = assignment.verification_claim
  json.id assignment.id
  json.username assignment.user.username
  json.real_name real_names[assignment.user_id]
  json.claim do
    json.sentence claim.sentence
    json.article_title claim.article_title&.tr('_', ' ')
  end
  json.taken_at assignment.updated_at
end
