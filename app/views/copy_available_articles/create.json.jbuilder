# frozen_string_literal: true

json.created @result.created_count
json.skipped @result.skipped_count
json.source do
  json.id @source.id
  json.slug @source.slug
  json.title pretty_course_title(@source)
end
# Same shape as /courses/:slug/assignments.json, so the frontend can replace
# its assignments list directly from this response.
json.course do
  json.partial! 'courses/assignments', course: @target
end
