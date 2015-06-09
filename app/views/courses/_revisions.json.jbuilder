json.revisions course.revisions.live.limit(50) do |rev|
  json.(rev, :id, :url, :characters, :date)

  json.(rev.article, :rating)
  json.article_url article_url(rev.article)
  json.title full_title(rev.article)
  json.rating_num rating_priority(rev.article.rating)
  json.pretty_rating rating_display(rev.article.rating)

  json.revisor rev.user.wiki_id
end
