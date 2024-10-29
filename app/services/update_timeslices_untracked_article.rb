# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"
require_dependency "#{Rails.root}/lib/revision_data_manager"

class UpdateTimeslicesUntrackedArticle
  include TimesliceHelper
  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
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
    @article_course_timeslices_to_untrack = ArticleCourseTimeslice.where(course: @course)
                                                                  .where(article_id: article_ids)
                                                                  .where(tracked: true)
    # Only reprocess those non-empty timeslices
    non_empty = @article_course_timeslices_to_untrack.where.not(user_ids: nil)
    # Mark course wiki timeslices that needs to be re-proccesed
    wikis_and_starts = @timeslice_manager.get_wiki_and_start_dates_to_reprocess(non_empty)
    @timeslice_manager.update_course_wiki_timeslices_that_need_update(wikis_and_starts)
    untrack_timeslices
  end

  def untrack_timeslices
    ids = @article_course_timeslices_to_untrack.map(&:id)
    ArticleCourseTimeslice.where(id: ids).update_all(tracked: 0) # rubocop:disable Rails/SkipsModelValidations
  end

  def retrack(article_ids)
    return if article_ids.empty?
    @article_course_timeslices_to_retrack = ArticleCourseTimeslice.where(course: @course)
                                                                  .where(article_id: article_ids)
                                                                  .where(tracked: false)
    # Only reprocess those non-empty timeslices
    non_empty = @article_course_timeslices_to_retrack.where.not(user_ids: nil)
    # Mark course wiki timeslices that needs to be re-proccesed
    wikis_and_starts = @timeslice_manager.get_wiki_and_start_dates_to_reprocess(non_empty)
    @timeslice_manager.update_course_wiki_timeslices_that_need_update(wikis_and_starts)
    retrack_timeslices
  end

  def retrack_timeslices
    ids = @article_course_timeslices_to_retrack.map(&:id)
    ArticleCourseTimeslice.where(id: ids).update_all(tracked: 1) # rubocop:disable Rails/SkipsModelValidations
  end
end
