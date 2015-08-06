json.revisions @revisions do |rev|
  json.(rev, :id, :characters, :views, :date, :url)
  json.article do
    if rev.article.nil?
      json.title 'Deleted article'
      json.url nil
    else
      json.title full_title(rev.article)
      json.url article_url(rev.article)
    end
  end
end
