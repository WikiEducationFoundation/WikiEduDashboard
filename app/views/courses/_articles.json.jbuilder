json.articles course.articles_courses.live do |ac|
  json.(ac, :character_sum, :view_count, :new_article)
  json.(ac.article, :id, :namespace, :rating)
  json.title full_title(ac.article)
  json.url article_url(ac.article)
  json.rating_num rating_priority(ac.article.rating)
  json.pretty_rating rating_display(ac.article.rating)
end
