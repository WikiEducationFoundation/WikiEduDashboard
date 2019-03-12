# frozen_string_literal: true

json.enroll_courses do
  json.partial! 'courses/users', course: @course
end
