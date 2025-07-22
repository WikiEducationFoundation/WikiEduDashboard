# Find the most commonly assigned article titles
# This script counts only one assignment per class, and excludes Available Articles that no student works on.
# It collects all titles with 5 or more assignments, ordered from most to least assignments.

assignment_instances = []
assignment_counts = Hash.new(0)

Assignment.where.not(user_id: nil).each do |assignment|
  assignment_instances << [assignment.article_title, assignment.course_id]
end

assignment_instances.count
assignment_instances.uniq.count
assignment_instances = assignment_instances.uniq
assignment_instances.each do |article_title, course_id|
  assignment_counts[article_title] += 1
end

frequent_assignments = []

assignment_counts.each do |key, value|
  next unless value > 4
  frequent_assignments << [key, value]
end

most_frequent_assignments = frequent_assignments.sort_by { |article_title, count| count }.reverse
puts most_frequent_assignments.map { |title, count| "#{title}, #{count}" }
