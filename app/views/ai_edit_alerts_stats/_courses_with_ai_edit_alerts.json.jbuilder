# frozen_string_literal: true

json.array! courses do |values|
  json.course values[:course].title
  json.course_slug values[:course].slug
  json.mainspace_count values[:mainspace_count]
  json.users_count values[:users_count]
end
