# Quick analysis of how many students were active in mainspace vs not, by term

headers = %w[campaign students active_count]
data = [headers]

Campaign.all.each do |campaign|
  total_students = CoursesUsers.where(role: 0, course: campaign.courses).count
  active_count = CoursesUsers.where(role: 0, course: campaign.courses).where.not(character_sum_ms: 0).count
  data << [campaign.slug, total_students, active_count]
end

CSV.open("/home/sage/active_students_by_term.csv", 'wb') do |csv|
  data.each { |line| csv << line }
end
