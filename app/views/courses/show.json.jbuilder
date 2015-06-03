json.course do
  json.(@course, :title, :description, :start, :end, :school, :term, :subject, :slug)
  json.partial! 'courses/courses_users', course: @course
  json.partial! 'courses/weeks', course: @course
end
