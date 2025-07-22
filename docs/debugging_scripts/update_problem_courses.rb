# When a course ought to be in the update cycle but hasn't been updated recently
# it may indicate a problem with the updates for that particular course.

RECENT_UPDATE_LIMIT = 3.days.ago
def updated_recently?(course)
  return false if course.flags['update_logs'].nil?
  last_start_time = course.flags['update_logs'].to_a.last[1]['start_time']
  return false if last_start_time.nil?
  last_start_time > RECENT_UPDATE_LIMIT
end

ids = Course.ready_for_update.filter { |c| puts c.id; !updated_recently?(c) }.map(&:id)
long_update_courses = Course.ready_for_update.filter { |c| c.flags[:very_long_update] }.map(&:id)

concerning_ids = ids - long_update_courses
puts concerning_ids

# Find courses from a campaign that haven't successfully updated since the end date
campaign = Campaign.find_by_slug 'coordinate_me_2025'
campaign.courses.each do |course|
  puts course.slug, course.id
  last_update_log = course.flags['update_logs'].values.last
  puts "last update: #{last_update_log['end_time']}"
  puts "errors: #{last_update_log['error_count']}"
  puts "reprocessed: #{last_update_log['reprocessed']}"
end; nil

