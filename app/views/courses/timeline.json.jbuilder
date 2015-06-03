json.course do
  json.partial! 'courses/courses_users', course: @course
  json.partial! 'courses/weeks', course: @course
end
