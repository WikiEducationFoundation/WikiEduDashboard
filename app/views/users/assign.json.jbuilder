json.course do
  json.partial! 'courses/courses_users', course: @course
end
