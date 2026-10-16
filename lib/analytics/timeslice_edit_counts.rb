# frozen_string_literal: true

# Edit counts that only article course timeslices hold, used by the course,
# campaign and system CSVs.
module TimesliceEditCounts
  NAMESPACES = [
    Article::Namespaces::MAINSPACE,
    Article::Namespaces::TALK,
    Article::Namespaces::USER
  ].freeze

  # Returns { namespace => edits } for the course's scoped articles.
  def self.by_namespace(course)
    course.scoped_article_timeslices
          .where(tracked: true)
          .joins(:article)
          .where(articles: { namespace: NAMESPACES })
          .group('articles.namespace')
          .sum(:revision_count)
  end

  # Returns { [course_id, namespace] => edits } for all the courses' articles, scoped or not.
  def self.by_course_and_namespace(course_ids)
    ArticleCourseTimeslice
      .where(tracked: true, course_id: course_ids)
      .joins(:article)
      .where(articles: { namespace: NAMESPACES })
      .group(:course_id, 'articles.namespace')
      .sum(:revision_count)
  end

  # Returns { wiki_id => edits } for the course's scoped articles.
  def self.by_wiki(course)
    course.scoped_article_timeslices
          .where(tracked: true)
          .joins(:article)
          .group('articles.wiki_id')
          .sum(:revision_count)
  end
end
