# frozen_string_literal: true

json.assignment do
  json.partial! 'assignments/assignment', course: assignment.course, assignment: assignment
end
