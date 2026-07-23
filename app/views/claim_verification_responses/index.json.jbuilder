# frozen_string_literal: true

# All of a course's exercise activity for the instructor view: submitted
# responses first, then students who have taken a claim but not yet submitted.
# Real names come from the course enrollment records, matching how the
# students tab identifies students to instructors.
real_names = CoursesUsers.where(course: @course).pluck(:user_id, :real_name).to_h

json.responses @responses do |response|
  claim = response.verification_claim
  json.username response.user.username
  json.real_name real_names[response.user_id]
  json.claim do
    json.sentence claim.sentence
    json.cite_text claim.cite_text
    json.source_url claim_source_url(claim)
    json.article_url claim_article_url(claim)
    json.article_title claim.article_title&.tr('_', ' ')
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
