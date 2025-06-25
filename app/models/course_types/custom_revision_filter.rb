# frozen_string_literal: true

module CustomRevisionFilter
  # This module contains the shared logic for ArticleScopedCourse
  # and VisitingCourse
  def scoped_article?(wiki, title, mw_page_id)
    # Normally, scoped_article_titles will include all the in-scope articles
    # but if the title of an assigned article has changed, we still want to process
    # edits to that article so that we can update the Assignment#article_title.
    # A secondary check against the mw_page_ids for assigned articles covers that.
    scoped_article_titles(wiki).include?(title) ||
      assigned_article_page_ids(wiki).include?(mw_page_id)
  end

  # For only-scoped-articles courses, we want to retrieve only the ACTs related
  # to scoped articles.
  def scoped_article_timeslices
    article_course_timeslices.where(article_id: scoped_article_ids)
  end
end
