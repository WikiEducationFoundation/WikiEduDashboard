# Course metadata
csv_data = [['course_slug',
             'start_date',
             'end_date',
             'assignment_start',
             'assignment_end',
             'byte_sum',
             'user_count',
             'expected_students',
             'article_count',
             'new_article_count',
             'revision_count',
             'upload_count',
             'uploads_in_use_count',
             'upload_usages_count',
             'references_count']]
ClassroomProgramCourse.nonprivate.each do |course|
  next if course.user_count.zero?
  csv_data << [course.slug, course.start, course.end, course.timeline_start, course.timeline_end, course.character_sum, course.user_count, course.expected_students, course.article_count, course.new_article_count, course.revision_count, course.upload_count, course.uploads_in_use_count, course.upload_usages_count, course.references_count]
end; nil

CSV.open("/home/sage/courses_with_metadata-#{Date.today}.csv", 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end; nil

# All instructors and students by course
csv_data = [['course_slug', 'username', 'global_id', 'role', 'enrolled_at']]
roles = { 1 => 'instructor', 0 => 'student' }
ClassroomProgramCourse.nonprivate.each do |course|
  next if course.user_count.zero?
  course.courses_users.includes(:user).each do |cu|
    next unless [0, 1].include?(cu.role)
    csv_data << [course.slug, cu.user.username, cu.user.global_id, roles[cu.role], cu.created_at]
  end
end; nil

CSV.open("/home/sage/student_program_students_and_instructors-#{Date.today}.csv", 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end; nil

# Articles edited by course
csv_data = [['course_slug', 'article_title', 'mediawiki_page_id', 'new_article', 'deleted']]
ClassroomProgramCourse.nonprivate.each do |course|
  next if course.user_count.zero?
  course.articles_courses.includes(:article).each do |ac|
    next unless ac.article.wiki_id == 1 # Skip non-en.wiki articles
    next unless ac.tracked # Skip explicitly un-tracked articles
    csv_data << [course.slug, ac.article.title, ac.article.mw_page_id, ac.new_article, ac.article.deleted]
  end
end; nil

CSV.open("/home/sage/articles_edited_by_course-#{Date.today}.csv", 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end; nil

# Assignments by course
csv_data = [['course_slug', 'username', 'assigned_title', 'assignment_type']]
ClassroomProgramCourse.nonprivate.each do |course|
  next if course.user_count.zero?
  course.assignments.includes(:user).each do |assignment|
    next unless assignment.user_id # Skip available articles
    next unless assignment.wiki_id == 1 # Skip non-en.wiki assignments
    assignment_type = assignment.role.zero? ? 'Editing' : 'Reviewing'
    csv_data << [course.slug, assignment.user.username, assignment.article_title, assignment_type]
  end
end; nil

CSV.open("/home/sage/assignments_by_course-#{Date.today}.csv", 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end; nil

# Course metadata - supplementary data late November 2025
csv_data = [['course_slug', 'course_level', 'academic_system', 'format']]
ClassroomProgramCourse.nonprivate.each do |course|
  next if course.user_count.zero?
  csv_data << [course.slug, course.level, course.academic_system, course.format]
end; nil

CSV.open("/home/sage/course_level-#{Date.today}.csv", 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end; nil

# Course demographics
# These are the student demographic surveys, which started in Spring 2020
demographic_survey_ids = [49, 47, 44, 42, 39, 37, 34, 32, 30, 28, 26, 22]
# Each survey has just one question group.
question_group_ids = demographic_survey_ids.map { |s_id| Survey.find(s_id).rapidfire_question_groups.first.id }
# => [80, 77, 74, 72, 70, 68, 66, 63, 61, 59, 55, 47] 
# First question of every question group is "What is your classification?"
# classification_q_ids = question_group_ids.map { |qg_id| Rapidfire::QuestionGroup.find(qg_id).questions.first.id }
# => [1921, 1860, 1802, 1756, 1706, 1652, 1605, 1512, 1450, 1382, 1262, 1002] 
# Second question of every question group is "What is your age"
# age_q_ids = question_group_ids.map { |qg_id| Rapidfire::QuestionGroup.find(qg_id).questions.second.id }
# => [1922, 1861, 1803, 1757, 1707, 1653, 1606, 1513, 1451, 1383, 1263, 1003] 

answer_groups = Rapidfire::AnswerGroup.where(question_group_id: question_group_ids); nil
responses_by_course = [['course_slug', 'response_date', 'classification', 'age', 'user_id']]
i = 0
answer_groups.each do |ag|
  puts i += 1
  next unless ag.course_id
  course_slug = Course.find(ag.course_id).slug
  response_date = ag.created_at
  classification = ag.answers.first.answer_text
  age = ag.answers.second.answer_text
  responses_by_course << [course_slug, response_date, classification, age, ag.user_id]
end; nil

CSV.open("/home/sage/student_demographics_by_course-#{Date.today}.csv", 'wb') do |csv|
  responses_by_course.each do |line|
    csv << line
  end
end; nil
