json.course do
  json.partial! 'courses/students', course: @course
  json.partial! 'courses/assignments', course: @course
end
