# frozen_string_literal: true

# This can be used to shift all of one Wikipedia Expert's courses to another,
# for a certain campaign.
old_id = User.find_by(username: 'Ian (Wiki Ed)').id
new_id = User.find_by(username: 'Sage (Wiki Ed)').id

Campaign.find_by(slug: 'spring_2017').courses.map do |course|
  ce = course.courses_users.find_by(user_id: old_id, role: 4)
  next unless ce
  ce.user_id = new_id
  ce.save
end

# Add one Wikipedia Expert to all courses in a campaign
expert = User.find_by(username: 'Ian (Wiki Ed)')
Campaign.find_by_slug('fall_2021').courses.each do |course|
  next if course.staff.include? expert
  JoinCourse.new(course: course, user: expert, role: 4, real_name: expert.real_name)
end

# Add one Wikipedia expert to courses that have none
# Skip if it already has Helaine plus a Wiki Expert in the staff role
expert = User.find_by(username: 'Ian (Wiki Ed)')
Campaign.find_by_slug('spring_2021').courses.each do |course|
  next if course.staff.count > 1 
  next if course.staff.include? expert
  JoinCourse.new(course: course, user: expert, role: 4, real_name: expert.real_name)
end
