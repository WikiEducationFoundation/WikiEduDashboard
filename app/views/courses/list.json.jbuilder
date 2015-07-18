json.course do
  json.partial! 'courses/cohorts', course: @course
  json.published CohortsCourses.exists?(course_id: @course.id)
end
