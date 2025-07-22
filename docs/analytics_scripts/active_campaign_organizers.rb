# script to find usernames of organizers of active campaigns, to invite to take the 2021 survey

usernames = []
Campaign.all.each do |campaign|
  puts "Campaign: #{campaign.title}"
  next unless campaign.courses.count > 5
  next unless campaign.courses.last.created_at < 18.months.ago
  usernames.concat campaign.organizers.pluck(:username)
end

puts usernames.uniq.sort
