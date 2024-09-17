# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

class CourseUserUpdater
  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
  end

  def run
    # Get the existing users in the course
    current_user_ids = @course.users.pluck(:id)
    # Users for whose exist a course user timeslice are considered processed
    processed_users = CourseUserWikiTimeslice.where(course: @course)
                                             .select(:user_id).distinct.pluck(:user_id)

    deleted_user_ids = processed_users - current_user_ids

    remove_courses_users(deleted_user_ids)
  end

  private

  def remove_courses_users(user_ids)
    return if user_ids.empty?
    # Delete course user wiki timeslices for the deleted users
    @timeslice_manager.delete_course_user_timeslices_for_deleted_course_users user_ids
    # Do this to avoid running the query twice
    @article_course_timeslices_for_users = get_article_course_timeslices_for_users(user_ids)
    # Mark course wiki timeslices that needs to be re-proccesed
    update_course_wiki_timeslices_for_deleted_course_users
    # Clean articles courses timeslices
    clean_article_course_timeslices
    # Delete articles courses that were updated only for removed users
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_for_user_ids(@course, user_ids)
  end

  # Returns ArticleCourseTimeslice records that have edits from users
  def get_article_course_timeslices_for_users(user_ids)
    timeslices = user_ids.map do |user_id|
      ArticleCourseTimeslice.search_by_course_and_user(@course, user_id)
    end

    # These are the ArticleCourseTimeslice records that were updated by users
    timeslices.flatten
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
  # removed users made some edits
  # Takes a collection of user ids
  def update_course_wiki_timeslices_for_deleted_course_users
    wikis_and_starts = get_wiki_and_start_dates_to_reprocess(@article_course_timeslices_for_users)

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

  def clean_article_course_timeslices
    ids = @article_course_timeslices_for_users.map(&:id)
    ArticleCourseTimeslice.where(id: ids).update_all(character_sum: 0, # rubocop:disable Rails/SkipsModelValidations
                                                     references_count: 0,
                                                     user_ids: nil)
  end
end
