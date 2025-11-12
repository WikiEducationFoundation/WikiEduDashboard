# frozen_string_literal: true

json.array! alerts do |alert|
  json.id alert.id
  json.timestamp alert.created_at
  json.course alert.course&.title
  json.course_slug alert.course&.slug
  json.article alert.article&.title
  json.user alert.user&.username
  json.diff_url alert.url
  json.pangram_url alert.pangram_url
end
