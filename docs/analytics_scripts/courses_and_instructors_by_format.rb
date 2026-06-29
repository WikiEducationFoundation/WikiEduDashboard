require 'csv'


camp = Campaign.find_by_slug 'spring_2025'
CSV.open("/home/sage/spring_2025_courses_by_format.csv", 'wb') do |csv|
  csv << %w[course_slug format first_instructor]
  camp.courses.each do |course|
    csv << [course.slug, course.flags['format'], course.instructors.first.real_name]
  end
end; nil
