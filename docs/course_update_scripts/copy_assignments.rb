# Script to copy the assigned and available articles for one course as available articles for another course

old_course = Course.find_by_slug 'University_of_Calgary/GLGY_209_-_Introduction_to_Geology_(Winter_2019)'
new_course = Course.find_by_slug 'University_of_Calgary/GLGY_209_-_Introduction_to_Geology_(Fall_2020)'

# This will copy all Available Articles and those assigned to students, which presumably captures
# the initial set of Available Articles before any were selected.
# Alternatively, `assignments.where(user_id: nil)` to copy only the remaining Available Articles
old_course.assignments.assigned.each do |assignment|
  Assignment.create(
    role: 0,
    article_title: assignment.article_title,
    article_id: assignment.article_id,
    wiki_id: assignment.wiki_id,
    course_id: new_course.id
  )
end
