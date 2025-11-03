experts = User.where(username: ['Ian (Wiki Ed)',
                                'Brianda (Wiki Ed)',
                                'Shalor (Wiki Ed)',
                                'Elysia (Wiki Ed)',
                                'Adam (Wiki Ed)',
                                'Rob (Wiki Ed)'])

years = 2015..2025

courses = years.map do |y|
  title = "Wiki Experts"
  school = 'WE'
  term = y.to_s
  slug = "#{school}/#{title}_(#{term})"
  start_date = "#{y}-01-01".to_date
  end_date = "#{y+1}-01-01".to_date
  Course.create!(title:, school:, term:, slug:, start: start_date, end: end_date, passcode: 'a', home_wiki_id: 1)
end

courses.each do |c|
  experts.each do |u|
    CoursesUsers.create!(course: c, user: u, role: 0)
  end
end


courses.each do |c|
  c.campaigns << Campaign.last  
end

courses.each do |c|
  UpdateCourseStats.new(c)
end