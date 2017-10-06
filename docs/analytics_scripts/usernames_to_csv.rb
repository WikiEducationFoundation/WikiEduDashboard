# frozen_string_literal: true

# This can be run in the rails console to generate a csv of all course
# participants' usernames.

require 'csv'

# all the usernames
usernames = User.joins(:courses_users).uniq.pluck(:username)
CSV.open('/root/all_course_participants.csv', 'wb') do |csv|
  usernames.each do |username|
    csv << [username]
  end
end

# student usernames by campaign
Campaign.all.each do |campaign|
  CSV.open("/root/#{campaign.slug}_students.csv", 'wb') do |csv|
    campaign.students.each do |student|
      csv << [student.username]
    end
  end
end

# student usernames and courses, by campaign
Campaign.all.each do |campaign|
  CSV.open("/root/#{campaign.slug}_students.csv", 'wb') do |csv|
    campaign.courses.each do |course|
      course.students.each do |student|
        csv << [student.username, course.slug]
      end
    end
  end
end

# courses, instructor usernames and ids
CSV.open('/root/course_instructors.csv', 'wb') do |csv|
  csv << ['course', 'instructor_user_id', 'instructor username']
  Course.all.each do |course|
    course.instructors.each do |instructor|
      csv << [course.slug, instructor.id, instructor.username]
    end
  end
end
