# frozen_string_literal: true

json.course do
  json.partial! 'courses/tags', course: @course
end
