# Investigating whether the 'no sandbox' courses are having the expected results.

fall_2025_courses = Campaign.find_by_slug('fall_2025').courses

no_sandbox_courses = fall_2025_courses.select { |course| course.tag? 'no_sandboxes' }
# 138
yes_sandbox_courses = fall_2025_courses.select { |course| course.tag? 'yes_sandboxes' }
# 64
default_sandbox_courses = fall_2025_courses - no_sandbox_courses - yes_sandbox_courses
# 141

headers = ['no_sandboxes?',
           'articles_edited',
           'revision_count',
           'students',
           'mainspace_edit_count',
           'mainspace_character_sum',
           'mainspace_references_count',
           'mainspace_ai_alerts',
           'total_ai_alerts']

stats = [headers]
fall_2025_courses.each do |course|
  puts course.slug
  stats << [
    course.no_sandboxes?,
    course.article_count,
    course.revision_count,
    course.user_count,
    course.article_course_timeslices.where(tracked: true).sum(:revision_count),
    course.article_course_timeslices.where(tracked: true).sum(:character_sum),
    course.references_count,
    course.alerts.where(type: 'AiEditAlert').count { |a| a.page_type == :mainspace },
    course.alerts.where(type: 'AiEditAlert').count
  ]
end

CSV.open("/home/sage/fall_2025_no_sandbox_courses.csv", 'wb') do |csv|
  stats.each { |line| csv << line }
end

stats = [headers]
no_sandbox_courses.each do |course|
  puts course.slug
  stats << [
    course.no_sandboxes?,
    course.article_count,
    course.revision_count,
    course.user_count,
    course.article_course_timeslices.where(tracked: true).sum(:revision_count),
    course.article_course_timeslices.where(tracked: true).sum(:character_sum),
    course.references_count,
    course.alerts.where(type: 'AiEditAlert').count { |a| a.page_type == :mainspace },
    course.alerts.where(type: 'AiEditAlert').count
  ]
end

CSV.open("/home/sage/no_sandbox_courses.csv", 'wb') do |csv|
  stats.each { |line| csv << line }
end

stats = [headers]
yes_sandbox_courses.each do |course|
  puts course.slug
  stats << [
    course.no_sandboxes?,
    course.article_count,
    course.revision_count,
    course.user_count,
    course.article_course_timeslices.where(tracked: true).sum(:revision_count),
    course.article_course_timeslices.where(tracked: true).sum(:character_sum),
    course.references_count,
    course.alerts.where(type: 'AiEditAlert').count { |a| a.page_type == :mainspace },
    course.alerts.where(type: 'AiEditAlert').count
  ]
end

CSV.open("/home/sage/yes_sandbox_courses.csv", 'wb') do |csv|
  stats.each { |line| csv << line }
end

stats = [headers]
default_sandbox_courses.each do |course|
  puts course.slug
  stats << [
    course.no_sandboxes?,
    course.article_count,
    course.revision_count,
    course.user_count,
    course.article_course_timeslices.where(tracked: true).sum(:revision_count),
    course.article_course_timeslices.where(tracked: true).sum(:character_sum),
    course.references_count,
    course.alerts.where(type: 'AiEditAlert').count { |a| a.page_type == :mainspace },
    course.alerts.where(type: 'AiEditAlert').count
  ]
end

CSV.open("/home/sage/default_sandbox_courses.csv", 'wb') do |csv|
  stats.each { |line| csv << line }
end

new_sandbox_courses = []
new_no_sandbox_courses = []
returning_sandbox_courses = []
returning_no_sandbox_courses = []

fall_2025_courses.each do |c|
  if c.returning_instructor?
    if c.no_sandboxes?
      returning_no_sandbox_courses << c
    else
      returning_sandbox_courses << c
    end
  else
    if c.no_sandboxes?
      new_no_sandbox_courses << c
    else
      new_sandbox_courses << c
    end
  end
end

def average_mainspace_edit_size(courses)
  total_character_sum = courses.sum { |course| course.article_course_timeslices.where(tracked: true).sum(:character_sum) }
  total_mainspace_edits = courses.sum { |course| course.article_course_timeslices.where(tracked: true).sum(:revision_count) }

  return 0 if total_mainspace_edits.zero?

  total_character_sum.to_f / total_mainspace_edits
end

def mainspace_edits_per_student(courses)
  total_mainspace_edits = courses.sum { |course| course.article_course_timeslices.where(tracked: true).sum(:revision_count) }
  total_students = courses.sum(&:user_count)

  return 0 if total_students.zero?

  total_mainspace_edits.to_f / total_students
end

average_mainspace_edit_size(new_sandbox_courses)
average_mainspace_edit_size(new_no_sandbox_courses)
average_mainspace_edit_size(returning_sandbox_courses)
average_mainspace_edit_size(returning_no_sandbox_courses)

mainspace_edits_per_student(new_sandbox_courses)
mainspace_edits_per_student(new_no_sandbox_courses)
mainspace_edits_per_student(returning_sandbox_courses)
mainspace_edits_per_student(returning_no_sandbox_courses)
