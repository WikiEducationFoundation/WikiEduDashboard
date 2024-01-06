# Get stats on how much per term has ended up in draft space

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

# Get the titles of all the edited articles for a term that ended up in Draft space

term = Campaign.find_by_slug 'fall_2023'
drafts = []

term.courses.each do |course|
  pp course.slug
  article_ids = course.revisions.pluck(:article_id).uniq
  drafts << Article.where(id: article_ids, namespace: 118).pluck(:title)
end

drafts.flatten!
puts drafts.count

File.open("/home/sage/drafts_2023.txt", "w+") do |f| 
  f.puts(drafts) 
end
