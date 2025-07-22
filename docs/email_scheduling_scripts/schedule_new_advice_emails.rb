# Script to schedule newly-implemented advice emails for courses that are already approved for the current term

campaign = Campaign.find_by_slug 'spring_2022'

campaign.courses.each do |course|
  scheduler = ScheduleCourseAdviceEmails.new(course, in_progress: true)
  scheduler.send(:schedule_choosing_an_article_email)
  scheduler.send(:schedule_bibliographies_email)
end
