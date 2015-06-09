json.course do
  json.(@course, :title, :description, :start, :end, :school, :term, :subject, :slug)
  json.partial! 'courses/uploads', course: @course
  json.partial! 'courses/students', course: @course
  json.partial! 'courses/articles', course: @course
  json.partial! 'courses/revisions', course: @course
  json.partial! 'courses/weeks', course: @course
end
