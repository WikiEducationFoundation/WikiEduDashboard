json.assignment do
  json.partial! 'assignments/assignment', course: assignment.course, assignment: assignment
end
