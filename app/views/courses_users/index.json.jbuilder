json.courses do
  json.array! @courses_users do |c_user|
    json.id c_user.course.id
    json.title cohort_title(c_user.course)
  end
end
