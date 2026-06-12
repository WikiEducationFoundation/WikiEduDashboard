# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_cleaner"
require_dependency "#{Rails.root}/lib/revision_data_manager"

# For ACUWT courses, re-fetches and re-scores only the (article, user) combinations
# whose ACUWT row has needs_update: true (set when score or wikidata-stats fetching failed),
# then marks the affected CWT timeslices for reaggregation.
#
# Replaces the full timeslice reprocess (fetch all revisions for the period, rebuild
# everything) with a targeted fix: only the failing (article, user) pairs are re-fetched.
# ACT, CUWT and CWT are rebuilt by the existing reaggregation flow.
class ReprocessArticleCourseUserWikiTimeslices
  def initialize(course, wiki, update_service: nil)
    @course = course
    @wiki = wiki
    @update_service = update_service
    @timeslice_cleaner = TimesliceCleaner.new(course)
  end

  def run
    periods_with_failing_acuwt.each do |(ts_start, ts_end)|
      reprocess_period(ts_start, ts_end)
    end
  end

  private

  def periods_with_failing_acuwt
    ArticleCourseUserWikiTimeslice.where(course: @course, wiki: @wiki, needs_update: true)
                                  .distinct.pluck(:start, :end)
  end

  def reprocess_period(ts_start, ts_end)
    article_ids = failing_article_ids_for(ts_start)
    users = ArticleCourseUserWikiTimeslice.users_for_articles_in_period(
      @course, @wiki, article_ids, ts_start
    )
    fetch_scores_and_update_acuwt(users, article_ids, ts_start, ts_end) if users.any?
    reset_for_reaggregation(article_ids, ts_start)
  end

  def failing_article_ids_for(ts_start)
    ArticleCourseUserWikiTimeslice.where(
      course: @course, wiki: @wiki, start: ts_start, needs_update: true
    ).distinct.pluck(:article_id)
  end

  def fetch_scores_and_update_acuwt(users, article_ids, ts_start, ts_end)
    revisions = fetch_filtered_revisions(users, article_ids, ts_start, ts_end)
    return if revisions.empty?

    revisions = revision_data_manager.fetch_score_data_for_course(revisions)
    update_wikidata_stats(revisions) if @wiki.project == 'wikidata'
    ArticleCourseUserWikiTimeslice.bulk_upsert_from_revisions(
      @course, @wiki, ts_start, ts_end, revisions
    )
  end

  def fetch_filtered_revisions(users, article_ids, ts_start, ts_end)
    revisions = revision_data_manager.fetch_revision_data_for_users_with_articles_only(
      users,
      ts_start.strftime('%Y%m%d%H%M%S'),
      (ts_end - 1.second).strftime('%Y%m%d%H%M%S')
    )
    revisions.select { |r| article_ids.include?(r.article_id) }
  end

  def update_wikidata_stats(revisions)
    live_revisions = revisions.reject(&:deleted)
    UpdateWikidataStatsTimeslice.new(@course).update_revisions_with_stats(live_revisions)
  end

  # Marks the CWT for reaggregation (deleting the stale ACT/CUWT rows) and clears
  # needs_update so the reaggregation pass picks it up. Reaggregation then rebuilds
  # ACT, CUWT and CWT from ACUWT and re-derives needs_update from ACUWT state.
  def reset_for_reaggregation(article_ids, ts_start)
    acuwt = ArticleCourseUserWikiTimeslice.where(
      course: @course, wiki: @wiki, start: ts_start, article_id: article_ids
    )
    @timeslice_cleaner.reset_timeslices_for_reaggregation_from_acuwt(acuwt)
    CourseWikiTimeslice.for_course_and_wiki(@course, @wiki)
                       .where(start: ts_start)
                       .update_all(needs_update: false) # rubocop:disable Rails/SkipsModelValidations
  end

  def revision_data_manager
    @revision_data_manager ||= RevisionDataManager.new(@wiki, @course,
                                                       update_service: @update_service)
  end
end
