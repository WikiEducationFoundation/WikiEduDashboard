# The tags for each approved student program course
unapproved_course_ids = Course.includes(:campaigns).where(campaigns: { id: nil }).references(:campaigns).pluck(:id)
approved_course_ids = ClassroomProgramCourse.all.pluck(:id) - unapproved_course_ids

i = 0
data = approved_course_ids.map do |id|
  i += 1
  puts i
  course = Course.find id
  tags = course.tags.pluck(:tag)
  [course.slug] + tags
end

CSV.open("/home/sage/tags_by_course.csv", 'wb') do |csv|
  data.each { |line| csv << line }
end

# Courses and instructors, for retention
headers = %w[course_slug instructor_username start_date end_date approved withdrawn submitted]
data = [headers]
all_course_ids = ClassroomProgramCourse.nonprivate.pluck(:id)
all_course_ids.each do |course_id|
  course = Course.find course_id
  course.instructors.each do |instructor|
    data << [course.slug, instructor.username, course.start, course.end, course.approved?, course.withdrawn, course.submitted]
  end
end

CSV.open("/home/sage/instructors_and_courses.csv", 'wb') do |csv|
  data.each { |line| csv << line }
end
