# Script to pull tabular data requested by Fiona Romero (Director, Community Programs at WMF)

# courses that happened in 2024-2025

courses = Course.where('start < ?', '2026-01-01'.to_date).where('end > ?', '2023-12-31'.to_date); nil

headers = ['Slug', 'Title', 'Institution', 'Start', 'End', 'Facilitator', 'Wikis', 'Participants', 'Edits']

data = [headers]

courses.each do |course|
  next if course.private
  course.instructors.each do |facilitator|
    row = [
      course.slug,
      course.title,
      course.school,
      course.start.to_s,
      course.end.to_s,
      facilitator.username,
      course.wikis.map(&:domain).join(','),
      course.user_count,
      course.revision_count
    ]
    data << row
  end
end; nil

CSV.open("/home/ragesoss/peony_2024-2025_data.csv", 'wb') do |csv|
  data.each { |line| csv << line }
end; nil
