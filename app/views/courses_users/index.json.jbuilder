# frozen_string_literal: true

json.courses do
  json.array! @courses_users.includes(course: :tags) do |course_user|
    course = course_user.course
    json.id course.id
    json.title pretty_course_title(course)
    json.type course.type
    json.cloneable !course.legacy? && !course.tag?('no_clone')
  end
end
