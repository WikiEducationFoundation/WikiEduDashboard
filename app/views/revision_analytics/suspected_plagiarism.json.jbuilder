json.revisions do
  json.array! @revisions do |revision|
    article = revision.article
    json.key article.id
    json.title full_title(article)
    json.article_url article_url(article)
    json.report_url revision.report_url
    json.user_wiki_id revision.user.wiki_id
    json.revision_datetime revision.date
    json.courses article.courses
  end
end
