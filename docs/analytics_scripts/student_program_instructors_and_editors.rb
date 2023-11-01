
require 'csv'

users = []
ClassroomProgramCourse.all.each { |c| puts c.slug; users += c.instructors.pluck(:username); users += c.students.pluck(:username) };

users.uniq!

CSV.open("/home/sage/scholars_and_scientists_editors.csv", 'wb') do |csv|
  users.each do |user|
    csv << [user]
  end
end