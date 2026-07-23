# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/cleaner_helper"
require_dependency "#{Rails.root}/lib/timeslice_cleaner"

#= Cleaner for ArticlesCourses that are not part of a course anymore.
class ArticlesCoursesCleaner # rubocop:disable Metrics/ClassLength
  include CleanerHelper

  ################
  # Entry points #
  ################

  def self.clean_articles_courses_for_wiki_ids(course, wiki_ids)
    new(course).remove_articles_courses_for_wiki_ids(wiki_ids)
  end

  def self.clean_articles_courses_for_user_ids(course, user_ids)
    new(course).remove_articles_courses_for_user_ids(user_ids)
  end

  def self.clean_articles_courses_prior_to_course_start(course)
    new(course).remove_articles_courses_for_dates_prior_to_start_date
  end

  def self.clean_articles_courses_after_course_end(course)
    new(course).remove_articles_courses_for_dates_after_end_date
  end

  def self.reset_specific_articles(course, articles)
    new(course).reset_specific_articles(articles)
  end

  def initialize(course)
    @course = course
  end

  # Removes the articles courses records belonging to articles in the given wiki ids.
  # We need to call this method when a tracked wiki is removed from a course.
  def remove_articles_courses_for_wiki_ids(wiki_ids)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles.where(wiki_id: wiki_ids).pluck(:id)

    return if article_ids.empty?

    delete_article_course(article_ids)
    Rails.logger.info "Deleted #{article_ids.size} ArticlesCourses from #{@course.title}"
  end

  # Removes the articles courses records that were edited only by users that got disenrolled
  # from the course.
  # We need to call this method when a course user is removed from a course.
  def remove_articles_courses_for_user_ids(user_ids)
    articles_courses = user_ids.map do |user_id|
      # Get all the articles courses edited by the user
      ArticlesCourses.search_by_course_and_user(@course, user_id)
    end.flatten.uniq

    to_delete = articles_courses.select do |article_course|
      # Only delete articles courses if every editor in that article was removed
      # articles_courses unless
      article_course.user_ids.all? { |editor| user_ids.include?(editor) }
    end.flatten

    to_delete.each_slice(5000) do |slice|
      ArticlesCourses.where(id: slice.map(&:id)).delete_all
      ArticleCourseTimeslice.where(course: @course, article_id: slice.map(&:article_id)).delete_all
    end
    Rails.logger.info "Deleted #{to_delete.size} ArticlesCourses from #{@course.title}"
  end

  def remove_articles_courses_for_dates_prior_to_start_date
    # Articles to be deleted are those that were edited only before the current start date
    article_ids_to_delete = article_ids_edited_beofre_start - article_ids_edited_after_start

    delete_article_course(article_ids_to_delete)

    # Delete article course timeslices for deleted articles
    delete_in_batches(
      ArticleCourseTimeslice.where(course: @course, article_id: article_ids_to_delete)
    )

    # Delete article course timeslices for dates prior to the course start date
    prior_timeslices = ArticleCourseTimeslice.where(course: @course)
                                             .where('end <= ?', @course.start)
    touch_timeslices(prior_timeslices.distinct.pluck(:article_id))
    delete_in_batches(prior_timeslices)
  end

  def remove_articles_courses_for_dates_after_end_date
    # Articles to be deleted are those that were edited only after the current end date
    article_ids_to_delete = article_ids_edited_after_end - article_ids_edited_before_end

    delete_article_course(article_ids_to_delete)

    # Delete article course timeslices for deleted articles
    delete_in_batches(
      ArticleCourseTimeslice.where(course: @course, article_id: article_ids_to_delete)
    )

    # Delete article course timeslices for dates after the course end date
    after_timeslices = ArticleCourseTimeslice.where(course: @course)
                                             .where('start > ?', @course.end)
    touch_timeslices(after_timeslices.distinct.pluck(:article_id))
    delete_in_batches(after_timeslices)
  end

  # Legacy reset (full re-fetch). It involves the following actions:
  # - Mark timeslices for those articles as needs_update
  # - Remove article course records for those articles (if they exist)
  # - Remove article course timeslices for those articles
  def reset_legacy(articles, wiki = nil)
    mark_as_needs_update(articles, wiki)
    delete_article_course(articles.pluck(:id))
  end

  # Resets articles that should be excluded from the course stats from now on
  # (e.g. articles that moved to an untracked namespace).
  # For ACUWT courses, no re-fetching is needed: the articles' ACUWT rows already hold
  # complete scored data, so reaggregating the affected timeslices is enough (the
  # aggregation filters exclude the articles). ACUWT rows are kept, so the articles can
  # be re-included later without a full re-fetch
  # (see ArticlesCourses.create_records_and_mark_acuwt).
  # For non-ACUWT courses, it falls back to the legacy reset.
  def reset_excluded(articles)
    return reset_legacy(articles) unless @course.use_acuwt?

    article_ids = articles.pluck(:id)
    acuwt = ArticleCourseUserWikiTimeslice.where(course: @course, article_id: article_ids)
    TimesliceCleaner.new(@course).reset_timeslices_for_reaggregation_from_acuwt(acuwt)
    delete_article_course(article_ids)
  end

  # Resets articles that should be included in the course stats from now on
  # (e.g. undeleted or re-tracked articles: tracked articles that have timeslices
  # but no articles_courses record).
  # For ACUWT courses, this is exactly the create-articles-courses-and-rescore case:
  # ArticlesCourses.create_records_and_mark_acuwt creates the records and marks the
  # articles' ACUWT rows as needs_update, so they are re-scored and the affected
  # timeslices reaggregated. No re-fetch of full periods is needed.
  # For non-ACUWT courses, it falls back to the legacy reset.
  def reset_included(articles, wiki = nil)
    return reset_legacy(articles, wiki) unless @course.use_acuwt?

    ArticlesCourses.create_records_and_mark_acuwt(@course, articles.map(&:id))
  end

  # Resets specific articles detected during the article status sync (stale,
  # deleted duplicates of a live copy for the same mw_page_id: see
  # ArticleStatusManager#handle_undeletion). This is a history-merge / undeletion
  # case where revisions must be re-ingested, so it needs a full per-period
  # re-fetch rather than a targeted rescore (reset_included) or reaggregation
  # (reset_excluded).
  # For ACUWT courses, the covering periods are derived from the articles' ACUWT
  # rows: those CWTs are marked needs_update (so they are fully re-fetched, and the
  # revisions re-attributed to the live copy, on the next update) and the ACUWT
  # rows for those periods (along with the ACT/CUWT rows derived from them) are
  # deleted so the re-fetch regenerates them cleanly, leaving no stale rows.
  # For non-ACUWT courses, it falls back to the legacy reset.
  def reset_specific_articles(articles)
    return reset_legacy(articles) unless @course.use_acuwt?

    acuwt = ArticleCourseUserWikiTimeslice.where(course: @course, article_id: articles.map(&:id))
    TimesliceCleaner.new(@course).reset_timeslices_for_update_from_acuwt(acuwt)
  end

  private

  # Returns article ids for every article edited before the current course start date
  def article_ids_edited_beofre_start
    ArticleCourseTimeslice.where(course: @course)
                          .where('end <= ?', @course.start)
                          .where.not(user_ids: nil)
                          .distinct
                          .pluck(:article_id)
  end

  # Returns article ids for every article edited before the current course start date
  def article_ids_edited_after_start
    ArticleCourseTimeslice.where(course: @course)
                          .where('start >= ?', @course.start)
                          .where.not(user_ids: nil)
                          .distinct
                          .pluck(:article_id)
  end

  # Returns article ids for every article edited after the current course end date
  def article_ids_edited_after_end
    ArticleCourseTimeslice.where(course: @course)
                          .where('start > ?', @course.end)
                          .where.not(user_ids: nil)
                          .distinct
                          .pluck(:article_id)
  end

  # Returns article ids for every article edited before the current course end date
  def article_ids_edited_before_end
    ArticleCourseTimeslice.where(course: @course)
                          .where('end <= ?', @course.end)
                          .where.not(user_ids: nil)
                          .distinct
                          .pluck(:article_id)
  end

  def delete_article_course(article_ids)
    article_ids.each_slice(DELETE_BATCH_SIZE) do |slice|
      ArticlesCourses.where(course: @course).where(article_id: slice).delete_all
    end
  end

  def mark_as_needs_update(article_batch, wiki)
    timeslices = @course.article_course_timeslices.where(article: article_batch)
    timeslice_cleaner = TimesliceCleaner.new(@course)
    timeslice_cleaner.reset_timeslices_that_need_update_from_article_timeslices(
      timeslices, wiki:
    )
  end

  def touch_timeslices(article_batch)
    # rubocop:disable Rails/SkipsModelValidations
    # Using touch to update the timestamps so article caches are updated during
    # next update
    ArticleCourseTimeslice.where(course: @course)
                          .where(article_id: article_batch)
                          .touch_all(:updated_at)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
