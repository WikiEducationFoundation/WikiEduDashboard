# Usernames of program organizers WMF Community Insights survey

CSV.open('/home/weswikied/leaders_with_wikis.csv', 'wb') do |csv|
  csv << %w[username program_slug joined_program_at program_wikis]

  CoursesUsers.where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE).each do |cu|
    next if cu.course.nil?
    csv << [cu.user.username, cu.course.slug, cu.created_at, cu.course.wikis.map(&:domain)]
  end
end
