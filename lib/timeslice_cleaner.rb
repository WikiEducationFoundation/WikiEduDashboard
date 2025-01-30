# frozen_string_literal: true

#= Removes/resets ArticleCourseTimeslice, CourseUserWikiTimeslice and CourseWikiTimeslice records.
class TimesliceCleaner
  def initialize(course)
    @course = course
  end

  # Deletes course user wiki timeslices records for removed course users
  # Takes a collection of user ids
  def delete_course_user_timeslices_for_deleted_course_users(user_ids)
    return if user_ids.empty?

    timeslice_ids = CourseUserWikiTimeslice.where(course: @course, user_id: user_ids).pluck(:id)

    return if timeslice_ids.empty?

    delete_course_user_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes course wiki timeslices records for removed course wikis
  # Deletes course user timeslices records for removed course wiki
  # Deletes article course timeslices records for removed course wiki
  # Takes a collection of wiki ids
  def delete_timeslices_for_deleted_course_wikis(wiki_ids)
    return if wiki_ids.empty?
    delete_existing_course_wiki_timeslices(wiki_ids)
    delete_existing_course_user_wiki_timeslices(wiki_ids)
    delete_existing_article_course_timeslices(wiki_ids)
  end

  # Deletes course wiki timeslices records with a date prior to the current start date
  def delete_course_wiki_timeslices_prior_to_start_date
    # Delete course wiki timeslices
    timeslice_ids = CourseWikiTimeslice.where(course: @course)
                                       .where('end <= ?', @course.start)
                                       .pluck(:id)

    delete_course_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes course wiki timeslices records with a start date later than the current end date
  def delete_course_wiki_timeslices_after_end_date
    wikis = @course.wikis
    delete_course_wiki_timeslices_after_date(wikis, @course.end)
  end

  # Deletes course wiki timeslices records with a start date later than the specific given date
  def delete_course_wiki_timeslices_after_date(wikis, date)
    # Delete course wiki timeslices
    timeslice_ids = CourseWikiTimeslice.where(course: @course)
                                       .where(wiki: wikis)
                                       .where('start > ?', date)
                                       .pluck(:id)

    delete_course_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes course user wiki timeslices records with a date prior to the current start date
  def delete_course_user_wiki_timeslices_prior_to_start_date
    # Delete course user wiki timeslices
    timeslice_ids = CourseUserWikiTimeslice.where(course: @course)
                                           .where('end <= ?', @course.start)
                                           .pluck(:id)

    delete_course_user_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes course user wiki timeslices records with a start date later than the current end date
  def delete_course_user_wiki_timeslices_after_end_date
    # Delete course user wiki timeslices
    timeslice_ids = CourseUserWikiTimeslice.where(course: @course)
                                           .where('start > ?', @course.end)
                                           .pluck(:id)

    delete_course_user_wiki_timeslice_ids(timeslice_ids)
  end

  # Resets course wiki timeslices. This involves:
  # - Marking timeslices as needs_update for dates with associated article course timeslices
  # - Deleting given article course timeslices if no soft
  # - Deleting course user wiki timeslices for those dates and wikis
  # Takes a collection of article course timeslices
  def reset_timeslices_that_need_update_from_article_timeslices(timeslices,
                                                                wiki: nil,
                                                                soft: false)
    return if timeslices.empty?

    wikis_and_starts = get_wiki_and_start_dates_to_reprocess(timeslices, wiki)

    # Prepare the list of tuples for SQL
    tuples_list = wikis_and_starts.map do |wiki_id, start_date|
      "(#{wiki_id}, '#{start_date}')"
    end.join(', ')

    # Perform the query using raw SQL for specific (wiki_id, start_date) pairs
    course_wiki_timeslices = CourseWikiTimeslice.where(course: @course)
                                                .where("(wiki_id, start) IN (#{tuples_list})")

    # Update all CourseWikiTimeslice records with matching course, wiki and start dates
    course_wiki_timeslices.update_all(needs_update: true) # rubocop:disable Rails/SkipsModelValidations

    delete_article_course_timeslice_ids(timeslices.pluck(:id)) unless soft

    # Perform the query using raw SQL for specific (wiki_id, start_date) pairs
    cuw_imeslices = CourseUserWikiTimeslice.where(course: @course)
                                           .where("(wiki_id, start) IN (#{tuples_list})")

    delete_course_user_wiki_timeslice_ids(cuw_imeslices.pluck(:id))
  end

  private

  # Deletes existing course wiki timeslices for a collection of wiki ids
  def delete_existing_course_wiki_timeslices(wiki_ids)
    # Collect the ids of timeslices to be deleted
    timeslice_ids = CourseWikiTimeslice.where(course_id: @course.id, wiki_id: wiki_ids).pluck(:id)

    return if timeslice_ids.empty?

    delete_course_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes existing course user wiki timeslices for a collection of wiki ids
  def delete_existing_course_user_wiki_timeslices(wiki_ids)
    # Collect the ids of timeslices to be deleted
    timeslice_ids = CourseUserWikiTimeslice.where(course_id: @course.id,
                                                  wiki_id: wiki_ids).pluck(:id)

    return if timeslice_ids.empty?

    delete_course_user_wiki_timeslice_ids(timeslice_ids)
  end

  # Deletes existing article course timeslices for a collection of wiki ids
  def delete_existing_article_course_timeslices(wiki_ids)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles_from_timeslices(wiki_ids).pluck(:id)

    # Collect the ids of timeslices to be deleted
    timeslice_ids = ArticleCourseTimeslice.where(course_id: @course.id,
                                                 article_id: article_ids).pluck(:id)

    return if timeslice_ids.empty?

    delete_article_course_timeslice_ids(timeslice_ids)
  end

  # Returns (wiki, start) tuples for timeslices to reprocess
  def get_wiki_and_start_dates_to_reprocess(article_course_timeslices, wiki = nil)
    # Extract article IDs and start dates as unique pairs
    articles_and_starts = article_course_timeslices.map do |timeslice|
      [timeslice.article_id, timeslice.start.strftime('%Y-%m-%d %H:%M:%S')]
    end.uniq

    return articles_and_starts.map { |_, start| [wiki, start] }.uniq if wiki

    # Fetch articles and map article IDs to their corresponding wiki IDs
    id_to_wiki_map = Article.where(id: articles_and_starts.map(&:first))
                            .index_by(&:id)
                            .transform_values(&:wiki_id)

    # Return unique combinations of wiki IDs and start dates
    articles_and_starts.map { |article_id, start| [id_to_wiki_map[article_id], start] }.uniq
  end

  def delete_article_course_timeslice_ids(ids)
    ids.each_slice(5000) do |slice|
      ArticleCourseTimeslice.where(id: slice).delete_all
    end
  end

  def delete_course_wiki_timeslice_ids(ids)
    ids.each_slice(5000) do |slice|
      CourseWikiTimeslice.where(id: slice).delete_all
    end
  end

  def delete_course_user_wiki_timeslice_ids(ids)
    ids.each_slice(5000) do |slice|
      CourseUserWikiTimeslice.where(id: slice).delete_all
    end
  end
end
