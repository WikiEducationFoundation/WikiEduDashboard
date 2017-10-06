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
