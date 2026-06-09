# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/timeslice_cleaner"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"
require_dependency "#{Rails.root}/lib/revision_data_manager"

# Adjusts timeslices when articles enter or leave scope in ArticleScopedProgram
# and VisitingScholarship courses.
#
# ACUWT path (course.use_acuwt? == true):
#   New articles (scoped, no articles_courses, but ACUWT rows exist from a prior update
#   when they were unscoped — those rows have revision data but zero references_count
#   and no wikidata stats): re-fetches revisions per timeslice period, filters to the
#   specific articles BEFORE the expensive reference-counter API call, upserts those
#   ACUWT rows with correct data, then marks the affected CWT timeslices for
#   reaggregation so ACT/CUWT/CWT are rebuilt without a full MediaWiki re-fetch.
#
#   Old articles (articles_courses present but no longer scoped): removes the
#   articles_courses and ACUWT rows, then marks affected CWT timeslices for reaggregation.
#
# Legacy path (course.use_acuwt? == false):
#   Both cases are handled by ArticlesCoursesCleanerTimeslice, marking CWT timeslices
#   as needs_update for a full re-fetch.
class UpdateTimeslicesScopedArticle
  def initialize(course, update_service: nil)
    @course = course
    @timeslice_cleaner = TimesliceCleaner.new(course)
    @scoped_article_ids = course.scoped_article_ids
    @update_service = update_service
  end

  def run
    return unless @course.only_scoped_articles_course?

    if @course.use_acuwt?
      handle_new_articles_acuwt
      handle_old_articles_acuwt
    else
      handle_new_articles_legacy
      handle_old_articles_legacy
    end
  end

  private

  ###############
  # ACUWT paths #
  ###############

  def handle_new_articles_acuwt
    new_article_ids = new_article_ids_with_acuwt_rows
    return if new_article_ids.empty?

    log_info "Fetching scores for new scoped articles: #{new_article_ids}"

    @course.wikis.each do |wiki|
      fetch_scores_and_update_acuwt(wiki, new_article_ids)
    end

    acuwt = ArticleCourseUserWikiTimeslice.where(course: @course, article_id: new_article_ids)
    @timeslice_cleaner.reset_timeslices_for_reaggregation_from_acuwt(acuwt)
  end

  def handle_old_articles_acuwt
    old_article_ids = unscoped_article_ids
    return if old_article_ids.empty?

    log_info "Removing old unscoped articles: #{old_article_ids}"

    acuwt = ArticleCourseUserWikiTimeslice.where(course: @course, article_id: old_article_ids)
    @timeslice_cleaner.reset_timeslices_for_reaggregation_from_acuwt(acuwt)
    ArticlesCourses.where(course: @course, article_id: old_article_ids).delete_all
  end

  # Scoped article IDs that lack articles_courses records but have existing ACUWT rows
  # (created when the articles were unscoped and scores were not fetched).
  def new_article_ids_with_acuwt_rows
    tracked_ids = @course.articles_courses
                         .where(article_id: @scoped_article_ids)
                         .pluck(:article_id)
    untracked_scoped_ids = @scoped_article_ids - tracked_ids
    return [] if untracked_scoped_ids.empty?

    ArticleCourseUserWikiTimeslice
      .where(course: @course, article_id: untracked_scoped_ids)
      .distinct.pluck(:article_id)
  end

  # For each timeslice period with ACUWT rows for the given articles, re-fetches
  # revisions for the relevant users, filters to the target articles before calling
  # the reference-counter API, then upserts the ACUWT rows with correct scores.
  # Also creates articles_courses records as a side effect of the revision fetch.
  def fetch_scores_and_update_acuwt(wiki, article_ids)
    manager = RevisionDataManager.new(wiki, @course, update_service: @update_service)
    periods = ArticleCourseUserWikiTimeslice.periods_for_articles(@course, wiki, article_ids)
    periods.each do |(ts_start, ts_end)|
      update_timeslice_for_new_articles(manager, wiki, article_ids, ts_start, ts_end)
    end
  end

  def update_timeslice_for_new_articles(manager, wiki, article_ids, ts_start, ts_end)
    users = ArticleCourseUserWikiTimeslice
              .users_for_articles_in_period(@course, wiki, article_ids, ts_start)
    return if users.empty?

    revisions = manager.fetch_revision_data_for_users_with_articles_only(
      users,
      ts_start.strftime('%Y%m%d%H%M%S'),
      (ts_end - 1.second).strftime('%Y%m%d%H%M%S')
    )
    # Filter to target articles BEFORE the expensive reference-counter API call
    revisions.select! { |r| article_ids.include?(r.article_id) }
    return if revisions.empty?

    revisions = manager.fetch_score_data_for_course(revisions)
    update_wikidata_stats(wiki, revisions) if wiki.project == 'wikidata'
    ArticlesCourses.update_from_course_revisions(@course, revisions)
    ArticleCourseUserWikiTimeslice.bulk_upsert_from_revisions(
      @course, wiki, ts_start, ts_end, revisions
    )
  end

  def update_wikidata_stats(wiki, revisions)
    live_revisions = revisions.reject(&:deleted)
    UpdateWikidataStatsTimeslice.new(@course).update_revisions_with_stats(live_revisions)
  end

  ################
  # Legacy paths #
  ################

  def handle_new_articles_legacy
    articles_with_timeslices = @course.article_course_timeslices
                                      .where(article_id: @scoped_article_ids)
                                      .pluck(:article_id)
    tracked_articles = @course.articles_courses
                              .where(article_id: @scoped_article_ids)
                              .pluck(:article_id)
    reset_legacy(articles_with_timeslices - tracked_articles)
  end

  def handle_old_articles_legacy
    reset_legacy(unscoped_article_ids)
  end

  def reset_legacy(article_ids)
    return if article_ids.empty?

    log_info "Resetting #{article_ids}"

    articles = Article.where(id: article_ids)
    ArticlesCoursesCleanerTimeslice.reset_specific_articles(@course, articles)
  end

  ###########
  # Helpers #
  ###########

  def unscoped_article_ids
    @course.articles_courses
           .where.not(article_id: @scoped_article_ids)
           .pluck(:article_id)
  end

  def log_info(message)
    Rails.logger.info "UpdateTimeslicesScopedArticle: Course: #{@course.slug} #{message}"
  end
end
