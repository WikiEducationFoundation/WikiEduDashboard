json.campaigns @values do |campaign|
  json.call(campaign, :id, :title, :slug)
  json.courses campaign.courses.count
  json.articles_created campaign.courses.sum(:new_article_count)
  json.articles_edited campaign.courses.sum(:article_count)
  json.words_added WordCount.from_characters(campaign.courses.sum(:character_sum))
  json.references_added campaign.courses.sum(:references_count)
  json.views campaign.courses.sum(:view_sum)
  json.editors campaign.courses.sum(:user_count)
end
