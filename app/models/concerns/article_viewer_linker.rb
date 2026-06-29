# Any object that has access to a course and an article can use
# that data to generate an article viewer link for that article and course.
module ArticleViewerLinker
  def article_viewer_link
    return nil unless course && article_id

    "https://#{ENV['dashboard_url']}/courses/#{course.slug}/articles/edited?showArticle=#{article_id}"
  end
end
