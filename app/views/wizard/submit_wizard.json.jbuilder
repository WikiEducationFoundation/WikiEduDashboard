# frozen_string_literal: true

json.course do
  json.partial! 'courses/weeks', course: @course
end
