# frozen_string_literal: true
json.course do
  json.partial! 'courses/cohorts', course: @course
end
