json.articles do
  json.array! @articles do |article|
    revision = article.revisions.last
    json.key article.id
    json.title full_title(article)
    json.article_url article_url(article)
    json.revision_score revision.wp10
    json.user_wiki_id revision.user.wiki_id
    json.revision_datetime revision.date
    json.courses article.courses
  end
end
