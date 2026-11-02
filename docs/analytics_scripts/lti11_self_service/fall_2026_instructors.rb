# frozen_string_literal: true

# Instructors of Fall 2026 courses at schools whose Canvas (or D2L) setup lets
# an instructor add the self-service LTI 1.1 tool without an admin, based on
# the 2026-09-17 web research. 'yes' schools were verified against a live
# institutional page; 'likely_yes' schools are ones where no restriction was found.
# Keys are the raw Course#school strings used on the Dashboard.
#
# Paste into a production Rails console. Writes one row per instructor.

require 'csv'

output_path = File.join(Dir.home, 'fall_2026_lti11_self_service_instructors.csv')

yes = ['Rutgers University', 'Rutgers University -- Camden',
       'Rutgers, the State University of New Jersey', 'Montclair State University',
       'UC Merced', 'Xavier University', 'Clemson University', 'University of Alberta']
likely_yes = [
  'University of Massachusetts Dartmouth', 'UMass Dartmouth', 'Del Mar College',
  'Rowan University', 'Vanderbilt University', 'Vanderbilt University School of Medicine',
  'Brown University', 'Warren Alpert Medical School of Brown University',
  'College of the Holy Cross', 'Pierce College Puyallup', 'Pratt Institute',
  'Southern Utah University', 'University of Maryland', 'Aquinas College', 'Auburn University',
  'Bradley University', 'Brigham Young University', 'Cal Poly Pomona',
  'California State University, Northridge', 'Case Western Reserve University',
  'Cerritos College', 'Duke University', 'East Carolina University',
  'Eastern Michigan University', 'Glendale Community College', 'Missouri S and T',
  'Murray State University', 'Northern Kentucky University', 'Northwestern University Qatar',
  'Rhodes College', 'Riverside City College', 'San Jose State University', 'Trinity University',
  'The University of Chicago', 'University of Cincinnati', 'University of Delaware',
  'University of Illinois- Springfield', 'University of Missouri St. Louis',
  'University of Nevada, Reno', 'University of New Hampshire', 'Washington College',
  'Weber State University', 'Western Washington University'
]
verdicts = yes.index_with { 'yes' }.merge(likely_yes.index_with { 'likely_yes' })

courses = Campaign.find_by(slug: 'fall_2026').courses
                  .where(school: verdicts.keys).includes(courses_users: :user)

CSV.open(output_path, 'wb') do |csv|
  csv << %w[verdict school course_slug instructor_name username email]
  courses.sort_by { |c| [verdicts[c.school], c.school, c.slug] }.each do |course|
    course.courses_users.select { |cu| cu.role == CoursesUsers::Roles::INSTRUCTOR_ROLE }
          .each do |cu|
      user = cu.user
      csv << [verdicts[course.school], course.school, course.slug,
              user.real_name.presence || cu.real_name, user.username, user.email]
    end
  end
end

puts "#{courses.count} courses written to #{output_path}"
