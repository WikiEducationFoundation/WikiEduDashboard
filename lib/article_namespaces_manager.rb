# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

##= Identifies articles that move to a different namespace during the course timeline.
# Specifically, it handles the following cases:
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
# Note: This class depends on the namespace attribute in the articles table. It does not update
# this attribute; it simply trusts its current value.

class ArticleNamespacesManager
  def initialize(course)
    @course = course

    reset_articles_that_moved_to_mainspace

    ArticlesCoursesCleanerTimeslice.reset_articles_in_untracked_namespaces(@course)
  end

  private

  def reset_articles_that_moved_to_mainspace
    articles = Article.find(moved_to_mainspace)
    ArticlesCoursesCleanerTimeslice.reset_specific_articles(@course, articles)
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
