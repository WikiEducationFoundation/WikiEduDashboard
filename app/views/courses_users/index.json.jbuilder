# frozen_string_literal: true

json.courses do
  json.array! @courses_users do |c_user|
    json.id c_user.course.id
    json.title pretty_course_title(c_user.course)
    json.type c_user.course.type
  end
end
