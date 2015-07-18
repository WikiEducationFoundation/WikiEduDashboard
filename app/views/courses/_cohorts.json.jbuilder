json.cohorts @course.cohorts do |ch|
  json.(ch, :id, :title)
end