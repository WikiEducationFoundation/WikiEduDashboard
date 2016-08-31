# frozen_string_literal: true
json.cohorts @course.cohorts do |cohort_course|
  json.call(cohort_course, :id, :title)
end
