# frozen_string_literal: true
require "#{Rails.root}/lib/article_utils"

module CustomRevisionFilter
  # This module contains the shared logic for ArticleScopedCourse
  # and VisitingCourse
  def filter_revisions(wiki, revisions)
    filtered_data = revisions.select do |_, details|
      article_title = details['article']['title']
      formatted_article_title = ArticleUtils.format_article_title(article_title, wiki)
      # Normally, scoped_article_titles will include all the in-scope articles
      # but if the title of an assigned article has changed, we still want to process
      # edits to that article so that we can update the Assignment#article_title.
      # A secondary check against the mw_page_ids for assigned articles covers that.
      scoped_article_titles(wiki).include?(formatted_article_title) ||
        assigned_article_page_ids(wiki).include?(details['article']['mw_page_id'].to_i)
    end
    filtered_data
  end
end
