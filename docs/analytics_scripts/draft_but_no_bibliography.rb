campaign = Campaign.find_by_slug 'fall_2021'
no_bibliography = [['course', 'title', 'exists?']]

campaign.courses.each do |course|
  puts course.slug
  sandboxes = course.sandboxes.map(&:title)
  course.assignments.each do |assignment|
    assignment_sandboxes = sandboxes.select { |sb| sb.include? assignment.article_title }
    next if assignment_sandboxes.empty?
    next if assignment_sandboxes.any? { |sb| sb.include? 'Bibliography' }
    no_bibliography << [course.slug, assignment.article_title, assignment.article_id.present?] + assignment_sandboxes
  end
end

File.write("/alloc/data/no_bibliography.csv", no_bibliography.map(&:to_csv).join)


## Bibliographies
campaign = Campaign.find_by_slug 'fall_2021'

bibliography_count = 0

campaign.courses.each do |course|
  bibliographies = course.sandboxes.map(&:title).select { |sb| sb.include? 'Bibliography' }
  bibliography_count += bibliographies.count
end

puts "Bibliography count: #{bibliography_count}"

campaign = Campaign.find_by_slug 'fall_2022'

from_list_courses = campaign.courses.select { |c| c.training_module_ids.include? 36 }
explore_courses = campaign.courses.to_a - from_list_courses

bibliography_count = 0
from_list_courses.each do |course|
  bibliographies = course.sandboxes.map(&:title).select { |sb| sb.include? 'Bibliography' }
  bibliography_count += bibliographies.count
end

bibliography_count = 0
explore_courses.each do |course|
  bibliographies = course.sandboxes.map(&:title).select { |sb| sb.include? 'Bibliography' }
  bibliography_count += bibliographies.count
end