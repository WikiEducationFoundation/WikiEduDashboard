# Script to get list of participants from 2019-2020, with timestamps of when they joined each course
require 'csv'
CSV.open("courses_users_2019-2020.csv", "w") do |csv|
  csv << ["username", "course", "timestamp", "role"]
  CoursesUsers.where('created_at > ?', '2018-12-31'.to_date).where('created_at < ?', '2021-01-01'.to_date).includes(:course, :user).each do |cu|
    csv << [cu.user.username, cu.course&.slug, cu.created_at, cu.role]
  end
end
