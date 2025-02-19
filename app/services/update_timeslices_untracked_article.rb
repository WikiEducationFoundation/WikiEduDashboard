# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_cleaner"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"
require_dependency "#{Rails.root}/lib/revision_data_manager"

class UpdateTimeslicesUntrackedArticle
  def initialize(course)
    @course = course
    @timeslice_cleaner = TimesliceCleaner.new(course)
  end

  def run
    # Get the untracked articles courses
    untracked_articles = @course.articles_courses.not_tracked.pluck(:article_id)
    untrack(untracked_articles)

    tracked_articles = @course.articles_courses.tracked.pluck(:article_id)
    retrack(tracked_articles)
  end

  private

  def untrack(article_ids)
    return if article_ids.empty?
    @article_course_timeslices_to_untrack = ArticleCourseTimeslice
                                            .for_course_and_article(@course, article_ids)
                                            .where(tracked: true)
    # Only reprocess those non-empty timeslices
    non_empty = @article_course_timeslices_to_untrack.where.not(user_ids: nil)
    # Mark course wiki timeslices that needs to be re-proccesed
    @timeslice_cleaner.reset_timeslices_that_need_update_from_article_timeslices(non_empty,
                                                                                 soft: true)
    untrack_timeslices
  end

  def untrack_timeslices
    ids = @article_course_timeslices_to_untrack.map(&:id)
    ArticleCourseTimeslice.where(id: ids).update_all(tracked: false) # rubocop:disable Rails/SkipsModelValidations
  end

  def retrack(article_ids)
    return if article_ids.empty?

    # Most of the time there are no untracked timeslices, so we can skip the retrack step
    has_untracked_timeslices = @course.article_course_timeslices.exists?(tracked: false)
    return unless has_untracked_timeslices

    @article_course_timeslices_to_retrack = ArticleCourseTimeslice
                                            .for_course_and_article(@course, article_ids)
                                            .where(tracked: false)
    # Only reprocess those non-empty timeslices
    non_empty = @article_course_timeslices_to_retrack.where.not(user_ids: nil)

    # Mark course wiki timeslices that needs to be re-proccesed
    @timeslice_cleaner.reset_timeslices_that_need_update_from_article_timeslices(non_empty)
    retrack_timeslices
  end

  def retrack_timeslices
    ids = @article_course_timeslices_to_retrack.map(&:id)
    ArticleCourseTimeslice.where(id: ids).update_all(tracked: 1) # rubocop:disable Rails/SkipsModelValidations
  end
end
