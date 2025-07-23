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
