# frozen_string_literal: true

json.assignments course.assignments
  .eager_load(:user, :wiki)
                       .includes(article: :wiki, course: :home_wiki) do |assignment|

  json.partial! 'assignments/assignment', course: assignment.course, assignment: assignment
end
