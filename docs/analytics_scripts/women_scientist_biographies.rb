# English Wikipedia articles tagged with the WikiProject Women scientists banner
category = Category.create(name: 'WikiProject_Women_scientists',
                           source: 'template', wiki_id: 1).refresh_titles

women_scientist_article_ids = category.article_ids # 11708 articles as of 2020-06-17
edited_article_ids = []
campaigns = ['summer_2019', 'fall_2019', 'spring_2020']

campaigns.each do |slug|
  campaign = Campaign.find_by_slug slug
  article_ids = campaign.articles.pluck(:id)
  edited_article_ids += article_ids
end

edited_women_scientists = edited_article_ids & women_scientist_article_ids

edited_women_scientists.count
# As of 2020-06-17, this shows 215 women scientist biographies edited by summer_2019,
# fall_2019, and spring_2020 cohorts on dashboard.wikiedu.org
# Not all women scientist biographies are tagged with the template, so this is an
# undercount.
