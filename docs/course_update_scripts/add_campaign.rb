# Add a set of courses to a campaign


# Courses in both of two campaigns will be added to a third
first_campaign = Campaign.find_by_slug('knowledge_equity')
second_campaign = Campaign.find_by_slug('spring_2024')
courses = first_campaign.courses & second_campaign.courses

to_add = Campaign.find_by_slug('knowledge_equity_on_wikipedia_20242026')

courses.each do |course|
  course.campaigns << to_add
end