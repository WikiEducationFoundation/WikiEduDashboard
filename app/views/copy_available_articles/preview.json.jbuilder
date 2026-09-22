# frozen_string_literal: true

json.source do
  json.id @source.id
  json.slug @source.slug
  json.title pretty_course_title(@source)
end
json.count @result.source_count
json.already_present @result.skipped_count
