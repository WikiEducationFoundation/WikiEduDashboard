# frozen_string_literal: true

json.alerts @alerts do |alert|
  json.id alert.id
  json.course_id alert.course_id
  json.user_id alert.user_id
  json.article_id alert.article_id
  json.revision_id alert.revision_id
  json.message alert.message
  json.target_user_id alert.target_user_id
  json.subject_id alert.subject_id
  json.details alert.details
  json.type alert.type
  json.created_at alert.created_at
  json.user alert.user&.username
  json.course alert.course&.title
  json.course_slug alert.course&.slug
  json.article alert.article&.title
  json.article_url alert.article&.url
  json.resolved alert.resolved
  json.resolvable alert.resolvable?
end
