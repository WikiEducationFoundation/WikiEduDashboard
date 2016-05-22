# Alert for when an article has been nominated for deletion on English Wikipedia
class ArticlesForDeletionAlert < Alert
  def main_subject
    "#{article.title} — #{course.try(:slug)}"
  end

  def url
    article_url(article)
  end
end
