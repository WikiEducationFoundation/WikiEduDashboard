# frozen_string_literal: true

module CustomRevisionFilter
  # This module contains the shared logic for ArticleScopedCourse
  # and VisitingCourse
  def filter_revisions(wiki, revisions)
    filtered_data = revisions.select do |_, details|
      article_title = details['article']['title']
      formatted_article_title = ArticleUtils.format_article_title(article_title, wiki)
      scoped_article_titles.include?(formatted_article_title)
    end
    filtered_data
  end
end
