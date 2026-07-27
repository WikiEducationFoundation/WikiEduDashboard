# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/cleaner_helper"

#= Removes/resets ArticleCourseTimeslice, CourseUserWikiTimeslice, CourseWikiTimeslice
#= and ArticleCourseUserWikiTimeslice records.
class TimesliceCleaner
  include CleanerHelper

  def initialize(course)
    @course = course
  end

  # Deletes every timeslice record for the course across the four timeslice
  # tables (ACUWT, ACT, CUWT, CWT). Used both when fully deleting a course and
  # when purging timeslices for old courses that are no longer updated.
  # Deletes in primary-key batches so each transaction stays small and ids are
  # never loaded into memory wholesale.
  def delete_all_timeslices_for_course
    delete_all_article_course_user_wiki_timeslices
    delete_all_article_course_timeslices
    delete_all_course_user_wiki_timeslices
    delete_all_course_wiki_timeslices
  end

  def delete_all_article_course_user_wiki_timeslices
    delete_in_batches(ArticleCourseUserWikiTimeslice.where(course: @course))
  end

  def delete_all_article_course_timeslices
    delete_in_batches(ArticleCourseTimeslice.where(course: @course))
  end

  def delete_all_course_user_wiki_timeslices
    delete_in_batches(CourseUserWikiTimeslice.where(course: @course))
  end

  def delete_all_course_wiki_timeslices
    delete_in_batches(CourseWikiTimeslice.where(course: @course))
  end

  # Deletes course user wiki timeslices records for removed course users
  # Takes a collection of user ids
  def delete_course_user_timeslices_for_deleted_course_users(user_ids)
    return if user_ids.empty?

    delete_in_batches(CourseUserWikiTimeslice.where(course: @course, user_id: user_ids))
  end

  # Deletes course wiki timeslices records for removed course wikis
  # Deletes course user timeslices records for removed course wiki
  # Deletes article course timeslices records for removed course wiki
  # Deletes article course user wiki timeslices records for removed course wiki
  # Takes a collection of wiki ids
  def delete_timeslices_for_deleted_course_wikis(wiki_ids)
    return if wiki_ids.empty?
    delete_existing_course_wiki_timeslices(wiki_ids)
    delete_existing_course_user_wiki_timeslices(wiki_ids)
    delete_existing_article_course_timeslices(wiki_ids)
    delete_existing_article_course_user_wiki_timeslices(wiki_ids)
  end

  # Deletes timeslices records in the period [start_date, end_date]
  def delete_timeslices_for_period(wikis, start_date, end_date)
    delete_course_wiki_timeslices_for_period(wikis, start_date, end_date)
    delete_course_user_wiki_timeslices_for_period(wikis, start_date, end_date)
    delete_article_course_timeslices_for_period(wikis, start_date, end_date)
    delete_article_course_user_wiki_timeslices_for_period(wikis, start_date, end_date)
  end

  # Deletes course wiki timeslices records with a date prior to the current start date
  def delete_course_wiki_timeslices_prior_to_start_date
    delete_in_batches(CourseWikiTimeslice.where(course: @course).where('end <= ?', @course.start))
  end

  # Deletes course wiki timeslices records with a start date later than the current end date
  def delete_course_wiki_timeslices_after_end_date
    wikis = @course.wikis
    delete_course_wiki_timeslices_after_date(wikis, @course.end)
  end

  # Deletes course wiki timeslices records with a start date later than the specific given date
  def delete_course_wiki_timeslices_after_date(wikis, date)
    timeslices = CourseWikiTimeslice.where(course: @course).where(wiki: wikis)
                                    .where('start > ?', date)
    delete_in_batches(timeslices)
  end

  # Deletes course user wiki timeslices records with a start date later than the
  # specific given date
  def delete_course_user_wiki_timeslices_after_date(wikis, date)
    timeslices = CourseUserWikiTimeslice.where(course: @course).where(wiki: wikis)
                                        .where('start > ?', date)
    delete_in_batches(timeslices)
  end

  # Deletes article course user wiki timeslices records with a start date later than
  # the specific given date
  def delete_article_course_user_wiki_timeslices_after_date(wikis, date)
    timeslices = ArticleCourseUserWikiTimeslice.where(course: @course).where(wiki: wikis)
                                               .where('start > ?', date)
    delete_in_batches(timeslices)
  end

  # Deletes article course timeslices records with a start date later than the
  # specific given date
  def delete_article_course_timeslices_after_date(wikis, date)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles_from_timeslices_legacy(wikis).pluck(:id)

    timeslices = ArticleCourseTimeslice.where(course: @course).where(article_id: article_ids)
                                       .where('start > ?', date)
    delete_in_batches(timeslices)
  end

  # Deletes course user wiki timeslices records with a date prior to the current start date
  def delete_course_user_wiki_timeslices_prior_to_start_date
    delete_in_batches(CourseUserWikiTimeslice.where(course: @course)
                                             .where('end <= ?', @course.start))
  end

  # Deletes course user wiki timeslices records with a start date later than the current end date
  def delete_course_user_wiki_timeslices_after_end_date
    delete_course_user_wiki_timeslices_after_date(@course.wikis, @course.end)
  end

  # Deletes article course user wiki timeslices records with a date prior to the
  # current start date
  def delete_article_course_user_wiki_timeslices_prior_to_start_date
    delete_in_batches(ArticleCourseUserWikiTimeslice.where(course: @course)
                                                    .where('end <= ?', @course.start))
  end

  # Deletes article course user wiki timeslices records with a start date later than
  # the current end date
  def delete_article_course_user_wiki_timeslices_after_end_date
    delete_article_course_user_wiki_timeslices_after_date(@course.wikis, @course.end)
  end

  # Marks CWT rows as needs_reaggregation for every (wiki, start) period covered
  # by the given ACUWT records, and deletes the ACT and CUWT rows for those
  # periods so they are cleanly re-derived during the next reaggregation pass.
  # Takes an ActiveRecord::Relation of ArticleCourseUserWikiTimeslice records.
  def reset_timeslices_for_reaggregation_from_acuwt(acuwt_records)
    return if acuwt_records.empty?

    wikis_and_starts = acuwt_records.pluck(:wiki_id, :start).uniq
    return if wikis_and_starts.empty?

    mark_timeslices_for_reaggregation(wikis_and_starts)
    delete_article_course_timeslices_for_acuwt_pairs(acuwt_records)
    delete_course_user_wiki_timeslices_for_acuwt_pairs(wikis_and_starts)
  end

  # Deletes the rows for the [start_date, end_date] period of a timeslice that is about to be
  # rewritten from a full re-fetch of that period, so that no rows survive for (article, user)
  # pairs the re-fetch did not return. Takes the fetched revisions for the period.
  #
  # Only the rows the rewrite will not cover are deleted. A timeslice holds up to
  # SplitTimeslice::REVISION_THRESHOLD revisions, so deleting the period wholesale and letting
  # the rewrite recreate it would mean thousands of deletes and inserts on every reprocess;
  # this way a reprocess that finds the same data as before deletes nothing. It also means the
  # rows that survive are updated in place, so the columns the rewrite does not write
  # (`tracked`) keep their value.
  #
  # ACUWT rows for articles deleted on wiki are kept: their revisions are gone from the
  # replica, so no re-fetch can reproduce them, and they are retained on purpose so the
  # articles can be re-included cheaply if they get undeleted (see
  # ArticlesCoursesCleaner#reset_included).
  #
  # Returns the ids of the articles left without any row for the period, so the caller can drop
  # the articles_courses records of those left without any timeslice in the course, once the
  # period has been rewritten (see
  # ArticlesCoursesCleaner#remove_articles_courses_without_timeslices).
  #
  # ACUWT courses only, since it diffs the stored ACUWT rows to decide what to delete.
  # The plucked rows are [id, article_id, user_id] tuples.
  def clean_timeslices_before_reprocessing(wiki, start_date, end_date, revisions)
    stored = ArticleCourseUserWikiTimeslice.where(course: @course, wiki:, start: start_date,
                                                  end: end_date)
                                           .pluck(:id, :article_id, :user_id)
    stale = stale_acuwt_rows(stored, fetched_pairs(revisions))
    return [] if stale.empty?

    delete_in_batches(ArticleCourseUserWikiTimeslice.where(id: stale.map { |row| row[0] }))
    article_ids, user_ids = emptied_article_and_user_ids(stored, stale)
    delete_aggregated_timeslices(wiki, start_date, end_date, article_ids, user_ids)
    article_ids
  end

  # Deletes ACUWT records for users removed from the course.
  # Takes a collection of user ids.
  def delete_acuwt_for_deleted_course_users(user_ids)
    return if user_ids.empty?

    delete_in_batches(ArticleCourseUserWikiTimeslice.where(course: @course, user_id: user_ids))
  end

  # Resets course wiki timeslices. This involves:
  # - Marking timeslices as needs_update for dates with associated article course timeslices
  # - Deleting given article course timeslices if no soft
  # - Deleting course user wiki timeslices for those dates and wikis
  # Takes an ActiveRecord::Relation of article course timeslices
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

    delete_in_batches(timeslices) unless soft

    # Perform the query using raw SQL for specific (wiki_id, start_date) pairs
    cuw_imeslices = CourseUserWikiTimeslice.where(course: @course)
                                           .where("(wiki_id, start) IN (#{tuples_list})")

    delete_in_batches(cuw_imeslices)
  end

  private

  # Deletes existing course wiki timeslices for a collection of wiki ids
  def delete_existing_course_wiki_timeslices(wiki_ids)
    delete_in_batches(CourseWikiTimeslice.where(course_id: @course.id, wiki_id: wiki_ids))
  end

  # Deletes existing course user wiki timeslices for a collection of wiki ids
  def delete_existing_course_user_wiki_timeslices(wiki_ids)
    delete_in_batches(CourseUserWikiTimeslice.where(course_id: @course.id, wiki_id: wiki_ids))
  end

  # Deletes existing article course user wiki timeslices for a collection of wiki ids
  def delete_existing_article_course_user_wiki_timeslices(wiki_ids)
    delete_in_batches(ArticleCourseUserWikiTimeslice.where(course_id: @course.id,
                                                           wiki_id: wiki_ids))
  end

  def mark_timeslices_for_reaggregation(wikis_and_starts)
    tuples = wikis_and_starts.map do |wiki_id, s|
      "(#{wiki_id}, '#{s.strftime('%Y-%m-%d %H:%M:%S')}')"
    end.join(', ')
    CourseWikiTimeslice.where(course: @course)
                       .where("(wiki_id, start) IN (#{tuples})")
                       .update_all(needs_reaggregation: true) # rubocop:disable Rails/SkipsModelValidations
  end

  def delete_article_course_timeslices_for_acuwt_pairs(acuwt_records)
    article_starts = acuwt_records.pluck(:article_id, :start).uniq
    return if article_starts.empty?

    tuples = article_starts.map do |article_id, s|
      "(#{article_id}, '#{s.strftime('%Y-%m-%d %H:%M:%S')}')"
    end.join(', ')
    delete_in_batches(ArticleCourseTimeslice.where(course: @course)
                                            .where("(article_id, start) IN (#{tuples})"))
  end

  def delete_course_user_wiki_timeslices_for_acuwt_pairs(wikis_and_starts)
    tuples = wikis_and_starts.map do |wiki_id, s|
      "(#{wiki_id}, '#{s.strftime('%Y-%m-%d %H:%M:%S')}')"
    end.join(', ')
    delete_in_batches(CourseUserWikiTimeslice.where(course: @course)
                                             .where("(wiki_id, start) IN (#{tuples})"))
  end

  # Deletes existing article course timeslices for a collection of wiki ids
  def delete_existing_article_course_timeslices(wiki_ids)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles_from_timeslices_legacy(wiki_ids).pluck(:id)

    delete_in_batches(ArticleCourseTimeslice.where(course_id: @course.id, article_id: article_ids))
  end

  # Returns (wiki, start) tuples for timeslices to reprocess
  def get_wiki_and_start_dates_to_reprocess(article_course_timeslices, wiki = nil)
    # Extract article IDs and start dates as unique pairs
    articles_and_starts = article_course_timeslices.map do |timeslice|
      [timeslice.article_id, timeslice.start.strftime('%Y-%m-%d %H:%M:%S')]
    end.uniq

    return articles_and_starts.map { |_, start| [wiki.id, start] }.uniq if wiki

    # Fetch articles and map article IDs to their corresponding wiki IDs
    id_to_wiki_map = Article.where(id: articles_and_starts.map(&:first))
                            .index_by(&:id)
                            .transform_values(&:wiki_id)

    # Return unique combinations of wiki IDs and start dates
    articles_and_starts.map { |article_id, start| [id_to_wiki_map[article_id], start] }.uniq
  end

  # Deletes course wiki timeslices records in the period [start_date, end_date]
  def delete_course_wiki_timeslices_for_period(wikis, start_date, end_date)
    timeslices = CourseWikiTimeslice.where(course: @course).where(wiki: wikis)
                                    .where('start >= ?', start_date)
                                    .where('end <= ?', end_date)
    delete_in_batches(timeslices)
  end

  # Deletes course user wiki timeslices records in the period [start_date, end_date]
  def delete_course_user_wiki_timeslices_for_period(wikis, start_date, end_date)
    timeslices = CourseUserWikiTimeslice.where(course: @course).where(wiki: wikis)
                                        .where('start >= ?', start_date)
                                        .where('end <= ?', end_date)
    delete_in_batches(timeslices)
  end

  # Deletes article course user wiki timeslices records in the period [start_date, end_date].
  # ACUWT rows are keyed by (course, wiki, article, user, start, end), so rows written for a
  # period that no longer exists as a timeslice (for example, after that period was split)
  # would otherwise linger and keep contributing to the aggregations derived from ACUWT.
  def delete_article_course_user_wiki_timeslices_for_period(wikis, start_date, end_date)
    timeslices = ArticleCourseUserWikiTimeslice.where(course: @course).where(wiki: wikis)
                                               .where('start >= ?', start_date)
                                               .where('end <= ?', end_date)
    delete_in_batches(timeslices)
  end

  # The [article_id, user_id] pairs found in the fetched revisions. Mirrors the filter in
  # ArticleCourseUserWikiTimeslice.acuwt_records_from_revisions, so that the pairs match the
  # rows the rewrite is going to write.
  def fetched_pairs(revisions)
    revisions.filter_map do |rev|
      [rev.article_id, rev.user_id] unless rev.article_id.nil? || rev.user_id.nil?
    end.to_set
  end

  # The stored rows whose (article, user) pair has no revision in the fetched data, leaving out
  # the ones for articles deleted on wiki. The Article lookup only runs when there is something
  # to delete, which is the uncommon case.
  def stale_acuwt_rows(stored, pairs)
    candidates = stored.reject { |row| pairs.include?([row[1], row[2]]) }
    return [] if candidates.empty?

    deleted_ids = Article.where(id: candidates.map { |row| row[1] }.uniq, deleted: true)
                         .pluck(:id)
    candidates.reject { |row| deleted_ids.include?(row[1]) }
  end

  # The articles and users whose every stored row for the period is being deleted, so their
  # aggregated rows for the period have to go too. Derived from the plucked rows, no queries.
  def emptied_article_and_user_ids(stored, stale)
    stale_ids = stale.map { |row| row[0] }.to_set
    surviving = stored.reject { |row| stale_ids.include?(row[0]) }
    [stale.map { |row| row[1] }.uniq - surviving.map { |row| row[1] },
     stale.map { |row| row[2] }.uniq - surviving.map { |row| row[2] }]
  end

  # Deletes the ACT and CUWT rows for the period belonging to the given articles and users.
  # Both tables' unique indexes lead with article_id and (course_id, user_id), so passing the
  # id lists is what keeps these deletes from scanning every row the course has.
  # ACT has no wiki_id, but an article belongs to a single wiki, so the article ids scope it.
  def delete_aggregated_timeslices(wiki, start_date, end_date, article_ids, user_ids)
    unless article_ids.empty?
      delete_in_batches(ArticleCourseTimeslice.where(course: @course, article_id: article_ids,
                                                     start: start_date, end: end_date))
    end
    return if user_ids.empty?

    delete_in_batches(CourseUserWikiTimeslice.where(course: @course, wiki:, user_id: user_ids,
                                                    start: start_date, end: end_date))
  end

  # Deletes article course timeslices records in the period [start_date, end_date]
  def delete_article_course_timeslices_for_period(wikis, start_date, end_date)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles_from_timeslices_legacy(wikis).pluck(:id)

    timeslices = ArticleCourseTimeslice.where(course: @course).where(article_id: article_ids)
                                       .where('start >= ?', start_date)
                                       .where('end <= ?', end_date)
    delete_in_batches(timeslices)
  end
end
