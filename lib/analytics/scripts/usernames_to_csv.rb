# This can be run in the rails console to generate a csv of all course
# participants' usernames.

require 'csv'

usernames = User.joins(:courses_users).uniq.pluck(:wiki_id)
CSV.open('/root/all_course_participants.csv', 'wb') do |csv|
  usernames.each do |username|
    csv << [username]
  end
end
