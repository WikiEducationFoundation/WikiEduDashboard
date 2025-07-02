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

# Course descriptions
headers = %w[course_slug description]
data = [headers]
ClassroomProgramCourse.nonprivate.each do |course|
  data << [course.slug, course.description]
end

CSV.open("/home/sage/course_descriptions.csv", 'wb') do |csv|
  data.each { |line| csv << line }
end

# Training completion data

csv_data = [['username', 'training_module', 'last_slide_completed', 'module_completion_date', 'started_at', 'last_slide_completed_at']]

TrainingModule.all.each do |tm|
  puts tm.slug
  tmus = TrainingModulesUsers.where(training_module_id: tm.id).includes(:user)
  puts tmus.count
  tmus.each do |tmu|
    csv_data << [tmu.user&.username, tm.slug, tmu.last_slide_completed, tmu.completed_at, tmu.created_at, tmu.updated_at]
  end
end

CSV.open('/home/sage/training_completion_all_users.csv', 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end

# All instructors and students by course

csv_data = [['course_slug', 'username', 'role', 'enrolled_at']]
roles = { 1 => 'instructor', 0 => 'student' }
ClassroomProgramCourse.nonprivate.each do |course|
  course.courses_users.includes(:user).each do |cu|
    next unless [0, 1].include?(cu.role)
    csv_data << [course.slug, cu.user.username, roles[cu.role], cu.created_at]
  end
end; nil

CSV.open('/home/sage/student_program_users.csv', 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end

# Survey questions
csv_data = [['question_id', 'question_type', 'question_text', 'answer_options', 'follow_up_question_text']]
Rapidfire::Question.all.each do |q|
  csv_data << [q.id, q.type, q.question_text, q.answer_options, q.follow_up_question_text]
end

CSV.open('/home/sage/all_survey_questions.csv', 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end