# frozen_string_literal: true

json.alerts @alerts.includes(:course, :user, article: :wiki) do |alert|
  json.id alert.id
  json.type alert.type
  json.created_at alert.created_at
  json.user alert.user&.username
  json.course alert.course.title
  json.course_slug alert.course.slug
  json.article alert.article&.title
  json.article_url alert.article&.url
end
