# This can be run in the rails console to generate a csv of all course
# participants' usernames.

require 'csv'

# all the usernames
usernames = User.joins(:courses_users).uniq.pluck(:wiki_id)
CSV.open('/root/all_course_participants.csv', 'wb') do |csv|
  usernames.each do |username|
    csv << [username]
  end
end

# student usernames by cohort
Cohort.all.each do |cohort|
  CSV.open("/root/#{cohort.slug}_students.csv", 'wb') do |csv|
    cohort.students.each do |student|
      csv << [student.wiki_id]
    end
  end
end
