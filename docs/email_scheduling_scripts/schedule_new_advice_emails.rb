# Script to schedule newly-implemented advice emails for courses that are already approved for the current term

campaign = Campaign.find_by_slug 'spring_2026'

# Method 1
campaign.courses.each do |course|
  scheduler = ScheduleCourseAdviceEmails.new(course, in_progress: true)
  scheduler.send(:schedule_choosing_an_article_email)
  scheduler.send(:schedule_bibliographies_email)
end

# Method 2
campaign.courses.each do |course|
  next unless course.tag?('research_write_assignment')
  puts course.slug
  send_date = course.timeline_start - 7.days
  CourseAdviceEmailWorker.schedule_email(course: course, subject: 'generative_ai', send_at: send_date)
end