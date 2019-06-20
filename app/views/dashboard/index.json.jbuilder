# frozen_string_literal: true

json.user do
  json.username current_user.username
end

json.current_courses @pres.current do |course|
  json.call(course, :id, :title, :school, :term, :slug, :created_at, :updated_at, :start, :end,
            :description)
end
json.past_courses @pres.past do |course|
  json.call(course, :id, :title, :school, :term, :slug, :created_at, :updated_at, :start, :end,
            :description)
end
