# frozen_string_literal: true

json.course do
  json.partial! 'assignments', course: @course
end
