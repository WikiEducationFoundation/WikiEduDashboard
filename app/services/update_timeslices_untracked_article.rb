# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"
require_dependency "#{Rails.root}/lib/revision_data_manager"

class UpdateTimeslicesUntrackedArticle
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
    wikis_and_starts = get_wiki_and_start_dates_to_reprocess(non_empty)
    update_course_wiki_timeslices_that_need_update(wikis_and_starts)
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
    wikis_and_starts = get_wiki_and_start_dates_to_reprocess(non_empty)
    update_course_wiki_timeslices_that_need_update(wikis_and_starts)
    retrack_timeslices
  end

  def retrack_timeslices
    ids = @article_course_timeslices_to_retrack.map(&:id)
    ArticleCourseTimeslice.where(id: ids).update_all(tracked: 1) # rubocop:disable Rails/SkipsModelValidations
  end

  # Returns (wiki, start) tuples for timeslices to reprocess
  def get_wiki_and_start_dates_to_reprocess(article_course_timeslices)
    # Extract article IDs and start dates as unique pairs
    articles_and_starts = article_course_timeslices.map do |timeslice|
      [timeslice.article_id, timeslice.start.strftime('%Y-%m-%d %H:%M:%S')]
    end.uniq

    # Fetch articles and map article IDs to their corresponding wiki IDs
    id_to_wiki_map = Article.where(id: articles_and_starts.map(&:first))
                            .index_by(&:id)
                            .transform_values(&:wiki_id)

    # Return unique combinations of wiki IDs and start dates
    articles_and_starts.map { |article_id, start| [id_to_wiki_map[article_id], start] }.uniq
  end

  # Marks course wiki timeslices as needs_update for those dates when
  # removed/new users made some edits
  # Takes a collection of user ids
  def update_course_wiki_timeslices_that_need_update(wikis_and_starts)
    return if wikis_and_starts.empty?

    # Prepare the list of tuples for SQL
    tuples_list = wikis_and_starts.map do |wiki_id, start_date|
      "(#{wiki_id}, '#{start_date}')"
    end.join(', ')

    # Perform the query using raw SQL for specific (wiki_id, start_date) pairs
    course_wiki_timeslices = CourseWikiTimeslice.where(course: @course)
                                                .where("(wiki_id, start) IN (#{tuples_list})")

    # Update all CourseWikiTimeslice records with matching course, wiki and start dates
    course_wiki_timeslices.update_all(needs_update: true) # rubocop:disable Rails/SkipsModelValidations
  end
end
