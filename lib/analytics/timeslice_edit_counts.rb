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

  # Returns { [course_id, namespace] => edits }, counting only scoped articles for
  # article scoped courses, like by_namespace. Resolving each course's scope is too slow
  # for batches (some categories hold a million titles), so scoped articles are taken
  # from articles_courses instead, which only has rows for them. This can differ from
  # by_namespace when the scope changed after the course's last update, or for scoped
  # articles that moved out of the tracked namespaces.
  def self.by_course_and_namespace(course_ids)
    scoped_ids = article_scoped_course_ids(course_ids)
    edits_by_course_and_namespace(course_ids - scoped_ids)
      .merge(edits_by_course_and_namespace(scoped_ids, only_articles_courses: true))
  end

  # Returns { wiki_id => edits } for the course's scoped articles.
  def self.by_wiki(course)
    course.scoped_article_timeslices
          .where(tracked: true)
          .joins(:article)
          .group('articles.wiki_id')
          .sum(:revision_count)
  end

  ARTICLE_SCOPED_TYPES = %w[ArticleScopedProgram VisitingScholarship].freeze

  # Article scoping comes from the course type or the article_scoped flag. The SQL
  # filter narrows the candidates down, so only those get their flags deserialized.
  def self.article_scoped_course_ids(course_ids)
    Course.where(id: course_ids)
          .where('type IN (?) OR flags LIKE ?', ARTICLE_SCOPED_TYPES, '%article_scoped%')
          .select(&:only_scoped_articles_course?)
          .map(&:id)
  end
  private_class_method :article_scoped_course_ids

  ARTICLES_COURSES_JOIN = <<~SQL.squish
    INNER JOIN articles_courses
      ON articles_courses.course_id = article_course_timeslices.course_id
      AND articles_courses.article_id = article_course_timeslices.article_id
  SQL

  def self.edits_by_course_and_namespace(course_ids, only_articles_courses: false)
    return {} if course_ids.empty?

    timeslices = ArticleCourseTimeslice.where(tracked: true, course_id: course_ids)
    timeslices = timeslices.joins(ARTICLES_COURSES_JOIN) if only_articles_courses
    timeslices.joins(:article)
              .where(articles: { namespace: NAMESPACES })
              .group('article_course_timeslices.course_id', 'articles.namespace')
              .sum(:revision_count)
  end
  private_class_method :edits_by_course_and_namespace
end
