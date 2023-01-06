stats = {}
Campaign.all.each do |campaign|
  puts campaign.slug
  draft = CoursesUsers.where(course: campaign.courses).sum(:character_sum_draft)
  mainspace = CoursesUsers.where(course: campaign.courses).sum(:character_sum_ms)
  next if mainspace.zero?
  ratio = draft.to_f / mainspace
  stats[campaign.slug] = { draft:, mainspace:, ratio: }
end

puts stats