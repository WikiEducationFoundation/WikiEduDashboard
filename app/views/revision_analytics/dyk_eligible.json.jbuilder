json.articles do
  json.array! @articles do |article|
    revision = article.revisions.order(wp10: :desc).first
    json.title article.title
    json.revision_score revision.wp10
    json.user_wiki_id User.find(revision.user_id).wiki_id
    json.revision_datetime revision.date
  end
end
