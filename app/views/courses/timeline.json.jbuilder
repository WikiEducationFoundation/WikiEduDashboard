# frozen_string_literal: true

json.course do
  json.partial! 'courses/weeks', course: @course
  json.training_library_slug @course.training_library_slug
end
