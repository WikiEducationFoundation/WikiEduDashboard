# This can be run in the rails console to get a CSV for each cohort

require 'csv'

Cohort.all.each do |cohort|
  CSV.open("/root/#{cohort.slug}.csv", 'wb') do |csv|
    csv << ['course_slug', 'students', 'characters_added']
    cohort.courses.each do |course|
      csv << [course.slug, course.students.count, course.character_sum]
    end
  end
end
