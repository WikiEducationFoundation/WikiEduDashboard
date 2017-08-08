class BlockedEditsAlert < Alert
  def main_subject
    "#{article.title}"
  end

  def url
    article_url(article)
  end
end
