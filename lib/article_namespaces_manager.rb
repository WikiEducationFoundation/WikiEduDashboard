# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/articles_courses_cleaner"

##= Resets articles whose tracked status changed during the course timeline, so
# that they are included in or excluded from course stats as appropriate.
# Resetting an article means marking its course wiki timeslices for reprocessing
# and removing its articles_courses record and article course timeslices
# (see ArticlesCoursesCleaner#reset).
#
# The following cases are handled for every course, including article scoped
# programs (which never run ArticleStatusManager), as a best effort to
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
#   This case is not handled here for ACUWT courses: reaggregation rebuilds article course
#   timeslices from ACUWT rows, so the created_at ordering this detection relies on is not
#   preserved. Instead, ArticlesCourses.update_from_course_revisions marks the article's
#   preexisting ACUWT rows as needs_update when it creates the article course record.
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
# (ArticleStatusManager is responsible for syncing them).

class ArticleNamespacesManager
  def initialize(course, statuses_synced: false)
    @course = course
    @cleaner = ArticlesCoursesCleaner.new(course)

    if statuses_synced
      reset_deleted_articles
      reset_undeleted_or_retracked_articles unless @course.only_scoped_articles_course?
    end
    # For ACUWT courses, this case is detected when the articles_courses record is
    # created instead (see ArticlesCourses.update_from_course_revisions).
    reset_articles_that_moved_to_mainspace unless @course.use_acuwt?
    reset_articles_in_untracked_namespaces
  end

  private

  def reset_deleted_articles
    deleted_ids = []
    # Note that this could remove articles courses records for manually untracked articles
    @course.articles.where(deleted: true).in_batches do |article_batch|
      deleted_ids += article_batch.pluck(:id)
      @cleaner.reset_legacy(article_batch)
    end
    log_reset('Article untracked', 'deleted', deleted_ids)
  end

  def reset_undeleted_or_retracked_articles
    retracked_ids = []
    @course.wikis.each do |wiki|
      # Find non-deleted and tracked articles without an articles_courses record
      @course.articles_from_timeslices(wiki.id)
             .where(deleted: false).in_batches do |article_batch|
        tracked = articles_in_tracked_namespaces(article_batch)
        tracked_without_articles_courses = tracked - @course.articles.to_a
        retracked_ids += tracked_without_articles_courses.map(&:id)
        @cleaner.reset_legacy(tracked_without_articles_courses, wiki)
      end
    end
    log_reset('Article retracked', 'undeleted_or_retracked', retracked_ids)
  end

  def reset_articles_that_moved_to_mainspace
    articles = Article.find(moved_to_mainspace)
    @cleaner.reset_legacy(articles)
    log_reset('Article retracked', 'moved_to_mainspace', articles.map(&:id))
  end

  def reset_articles_in_untracked_namespaces
    untracked_ids = []
    @course.articles.in_batches do |article_batch|
      tracked_ids = articles_in_tracked_namespaces(article_batch).map(&:id)
      # Find articles with articles_courses records but not in tracked namespaces
      untracked_articles = article_batch.where.not(id: tracked_ids)
      untracked_ids += untracked_articles.pluck(:id)
      @cleaner.reset_excluded(untracked_articles)
    end
    log_reset('Article untracked', 'moved_to_untracked_namespace', untracked_ids)
  end

  # This scenario is hard to reproduce (it requires an article to move namespaces
  # in the middle of course updates), so we log it to learn how frequent it is.
  def log_reset(message, reason, article_ids)
    return if article_ids.empty?
    Sentry.capture_message message,
                           level: 'info',
                           extra: { course_slug: @course.slug, course_id: @course.id,
                                    reason:, article_ids: }
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
