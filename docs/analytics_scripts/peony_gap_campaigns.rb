# Data about Wikigap, A+F and Women in Red events from Peony
# 
# slug, editors, articles created, articles edited, start, end, tracked wikis, name, institution, campaigns
# 
# https://outreachdashboard.wmflabs.org/campaigns/wikigap_2018/programs
# https://outreachdashboard.wmflabs.org/campaigns/campaign_wikigap_2019/programs
# https://outreachdashboard.wmflabs.org/campaigns/wikigap_2020/programs
# https://outreachdashboard.wmflabs.org/campaigns/wikigap_2021/programs
# https://outreachdashboard.wmflabs.org/campaigns/wikigap_2022/programs
# https://outreachdashboard.wmflabs.org/campaigns/wikigap_2023/programs
# https://outreachdashboard.wmflabs.org/explore?search=wikigap+2024


# https://outreachdashboard.wmflabs.org/campaigns/artfeminism_2018/programs
# https://outreachdashboard.wmflabs.org/campaigns/artfeminism_2019/programs
# https://outreachdashboard.wmflabs.org/campaigns/artfeminism_2020/programs
# https://outreachdashboard.wmflabs.org/campaigns/artfeminism_2021/programs
# https://outreachdashboard.wmflabs.org/campaigns/artfeminism_2022/programs
# https://outreachdashboard.wmflabs.org/campaigns/artfeminism_2023/programs
# https://outreachdashboard.wmflabs.org/campaigns/artfeminism_2024/programs


campaign_slugs = [
  'wikigap_2018',
  'campaign_wikigap_2019',
  'wikigap_2020',
  'wikigap_2021',
  'wikigap_2022',
  'wikigap_2023',
  'artfeminism_2018',
  'artfeminism_2019',
  'artfeminism_2020',
  'artfeminism_2021',
  'artfeminism_2022',
  'artfeminism_2023',
  'artfeminism_2024'
]

wikigap_2024_course_ids = [27564, 27660, 27674]

course_ids = wikigap_2024_course_ids

campaign_slugs.each do |slug|
  ids = Campaign.find_by(slug: slug).courses.nonprivate.map(&:id)
  course_ids += ids
end

# 1502 courses, 1483 unique courses
course_ids.uniq!

headers = %w[slug editors articles_created articles_edited revision_count activity_start activity_end tracked_wikis name institution campaigns]
data = [headers] 

course_ids.each do |cid|
  c = Course.find(cid)
  row = []
  row << c.slug
  row << c.user_count
  row << c.new_article_count
  row << c.article_count
  row << c.revision_count
  row << c.start.to_s
  row << c.end.to_s
  row << c.wikis.map(&:domain).join(', ')
  row << c.title
  row << c.school
  row << c.campaigns.map(&:slug).join(', ')
  data << row
end

CSV.open("/home/ragesoss/mali_data.csv", 'wb') do |csv|
  data.each { |line| csv << line }
end