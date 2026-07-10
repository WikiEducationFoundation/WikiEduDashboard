# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/articles_courses_cleaner"

##= Resets articles whose tracked status changed during the course timeline, so
# that they are included in or excluded from course stats as appropriate.
# Resetting an article means marking its course wiki timeslices for reprocessing
# and removing its articles_courses record and article course timeslices
# (see ArticlesCoursesCleaner#reset).
#
# The following cases are handled for every course, including article scoped
# programs (which never run ArticleStatusManagerTimeslice), as a best effort to
# detect namespace moves without re-syncing article statuses:
#
# 1- Articles that moved from a non-tracked namespace to a tracked namespace (usually mainspace).
#   These are identified when the article course record is created *after* some of its article
#   course timeslices.
#   This implies the article had revisions that didn't trigger article course record creation
#   (because it wasn't relevant yet). Later, the article course record was created —likely because
#   the article moved to a tracked namespace and became relevant.
#   In such cases, we need to flag the timeslices for reprocessing, since previous stats weren't
#   counted as tracked-namespace stats.
#
# 2- Articles that moved from a tracked namespace to a non-tracked namespace.
#
# Additionally, when article statuses were just synced (statuses_synced: true), it handles:
#
# 3- Articles that were deleted.
#
# 4- Articles that were undeleted or re-tracked: tracked articles with article course
#   timeslices but no articles_courses record.
#   This must never run for courses that only track a specific list of articles: non-scoped
#   articles get article course timeslices but never an articles_courses record, so they
#   would be reset (and reprocessed) on every update.
#
# Note: This class depends on the namespace and deleted attributes in the articles table.
# It does not update those attributes; it simply trusts their current values
# (ArticleStatusManagerTimeslice is responsible for syncing them).

class ArticleNamespacesManager
  def initialize(course, statuses_synced: false)
    @course = course
    @cleaner = ArticlesCoursesCleaner.new(course)

    if statuses_synced
      reset_deleted_articles
      reset_undeleted_or_retracked_articles unless @course.only_scoped_articles_course?
    end
    reset_articles_that_moved_to_mainspace
    reset_articles_in_untracked_namespaces
  end

  private

  def reset_deleted_articles
    # Note that this could remove articles courses records for manually untracked articles
    @course.articles.where(deleted: true).in_batches do |article_batch|
      @cleaner.reset(article_batch)
    end
  end

  def reset_undeleted_or_retracked_articles
    @course.wikis.each do |wiki|
      # Find non-deleted and tracked articles without an articles_courses record
      @course.articles_from_timeslices(wiki.id)
             .where(deleted: false).in_batches do |article_batch|
        tracked = articles_in_tracked_namespaces(article_batch)
        tracked_without_articles_courses = tracked - @course.articles.to_a
        @cleaner.reset(tracked_without_articles_courses, wiki)
      end
    end
  end

  def reset_articles_that_moved_to_mainspace
    articles = Article.find(moved_to_mainspace)
    @cleaner.reset(articles)
  end

  def reset_articles_in_untracked_namespaces
    @course.articles.in_batches do |article_batch|
      tracked_ids = articles_in_tracked_namespaces(article_batch).map(&:id)
      # Find articles with articles_courses records but not in tracked namespaces
      untracked_articles = article_batch.where.not(id: tracked_ids)
      @cleaner.reset(untracked_articles)
    end
  end

  def articles_in_tracked_namespaces(article_batch)
    @course.tracked_namespaces.flat_map do |wiki_ns|
      article_batch.where(wiki_id: wiki_ns[:wiki].id, namespace: wiki_ns[:namespace])
    end
  end

  # Articles that have an article course record that was created *after* some of its article
  # course timeslices.
  def moved_to_mainspace
    @course.articles_courses
           .joins('INNER JOIN article_course_timeslices act ON act.course_id = articles_courses.course_id AND act.article_id = articles_courses.article_id') # rubocop:disable Layout/LineLength
           .where('act.created_at < articles_courses.created_at')
           .pluck(:article_id)
           .uniq
  end
end
