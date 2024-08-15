# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/article_status_manager"
require_dependency "#{Rails.root}/lib/importers/course_upload_importer"
require_dependency "#{Rails.root}/lib/data_cycle/update_logger"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"
require_dependency "#{Rails.root}/lib/importers/revision_score_importer"
require_dependency "#{Rails.root}/lib/importers/average_views_importer"
require_dependency "#{Rails.root}/lib/errors/update_service_error_helper"
require_dependency "#{Rails.root}/lib/data_cycle/course_queue_sorting"
require_dependency "#{Rails.root}/lib/timeslice_manager"

#= Pulls in new revisions for a single course wiki timeslice and updates the corresponding records
class UpdateCourseStatsTimeslice # rubocop:disable Metrics/ClassLength
  include UpdateServiceErrorHelper
  include CourseQueueSorting

  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(@course)
    # If the upate was explicitly requested by a user,
    # it could be because the dates or other paramters were just changed.
    # In that case, do a full update rather than just fetching the most
    # recent revisions.
    # @full_update = full || @course.needs_update

    @start_time = Time.zone.now
    fetch_data
    update_categories
    update_article_status if should_update_article_status?
    update_average_pageviews
    update_caches
    # update_wikidata_stats if wikidata
    # This needs to happen after `update_caches` because it relies on ArticlesCourses#new_article
    # to calculate new article stats for each namespace.
    # update_wiki_namespace_stats
    @course.update(needs_update: false)
    @end_time = Time.zone.now
    UpdateLogger.update_course(@course, 'start_time' => @start_time.to_datetime,
                                         'end_time' => @end_time.to_datetime,
                                         'sentry_tag_uuid' => sentry_tag_uuid,
                                         'error_count' => error_count)
  end

  private

  def fetch_data
    log_update_progress :start
    # Fetchs revision for each wiki
    @revisions = CourseRevisionUpdater.fetch_revisions_and_scores(@course,
                                                                  update_service: self)

    log_update_progress :revision_scores_fetched

    # TODO: replace the logic on ArticlesCourses.update_from_course to remove all
    # the ArticlesCourses that do not correspond to course revisions.
    # That may happen if the course dates changed, so some revisions are no
    # longer part of the course.
    # Also remove records for articles that aren't on a tracked wiki.

    # TODO: note this is not wiki scoped.
    CourseUploadImporter.new(@course, update_service: self).run
    log_update_progress :uploads_imported
  end

  def update_categories
    # TODO: note this is not wiki scoped.
    Category.refresh_categories_for(@course)
    log_update_progress :categories_updated
  end

  def update_article_status
    # TODO: note this is not wiki scoped.
    ArticleStatusManager.update_article_status_for_course(@course)
    log_update_progress :article_status_updated

    # TODO: replace the logic on ModifiedRevisionsManager.new(@wiki).move_or_delete_revisions
  end

  def update_average_pageviews
    # TODO: note this is not wiki scoped.
    AverageViewsImporter.update_outdated_average_views(@course.articles)
    log_update_progress :average_pageviews_updated
  end

  def update_article_course_timeslices_for_wiki(revisions, timeslice_start)
    revisions.group_by(&:article_id).each do |article_id, article_revisions|
      # We don't create articles courses for every article
      article_course = ArticlesCourses.find_by(course: @course, article_id:)
      next unless article_course
      # Update cache for ArticleCorseTimeslice
      ArticleCourseTimeslice.find_by(
        article_id:,
        course_id: @course.id,
        start: timeslice_start
      ).update_cache_from_revisions article_revisions
    end
  end

  def update_course_user_wiki_timeslices_for_wiki(revisions, timeslice_start, wiki)
    revisions.group_by(&:user_id).each do |user_id, user_revisions|
      # Update cache for CourseUserWikiTimeslice
      CourseUserWikiTimeslice.find_by(
        course: @course,
        user_id:,
        wiki:,
        start: timeslice_start
      ).update_cache_from_revisions user_revisions
    end
  end

  def update_course_wiki_timeslices_for_wiki(revisions, timeslice_start, wiki)
    # Update cache for CourseWikiTimeslice
    CourseWikiTimeslice.find_by(
      course: @course,
      wiki:,
      start: timeslice_start
    ).update_cache_from_revisions revisions
  end

  def update_timeslices
    return if @revisions.length.zero?
    @course.wikis.each do |wiki|
      # Exclude revisions with date = max date. These excluded revisions will be fetched
      # and processed during the next update.
      revisions_to_process = @revisions[wiki][:revisions].reject do |revision|
        revision.date == @revisions[wiki][:end]
      end
      # Group revisions by timeslice
      # TODO: make this work independtly on the timeslice duration
      # Right now only works for daily timeslices
      revisions_to_process.group_by { |revision| revision.date.to_date }
                          .each do |timeslice_start, revisions|
        update_article_course_timeslices_for_wiki(revisions, timeslice_start)

        update_course_user_wiki_timeslices_for_wiki(revisions, timeslice_start, wiki)

        update_course_wiki_timeslices_for_wiki(revisions, timeslice_start, wiki)
      end
    end
  end

  def update_caches
    ActiveRecord::Base.transaction do
      update_timeslices
      ArticlesCourses.update_all_caches_from_timeslices(@course.articles_courses)
      log_update_progress :articles_courses_updated
      CoursesUsers.update_all_caches_from_timeslices(@course.courses_users)
      log_update_progress :courses_users_updated
      @course.reload
      @course.update_cache_from_timeslices
      HistogramPlotter.delete_csv(course: @course) # clear cached structural completeness data
      log_update_progress :course_cache_updated

      @timeslice_manager.update_last_mw_rev_datetime(@revisions)

    rescue StandardError => e
      log_error(e)
      raise ActiveRecord::Rollback
    end
  end

  def update_wikidata_stats
    UpdateWikidataStatsWorker.new.perform(@course)
    log_update_progress :wikidata_stats_updated
  end

  def update_wiki_namespace_stats
    # Update each of the tracked namespaces
    @course.course_wiki_namespaces.each do |course_wiki_ns|
      wiki = course_wiki_ns.courses_wikis.wiki
      namespace = course_wiki_ns.namespace
      UpdateWikiNamespaceStats.new(@course, wiki, namespace)
    end
    # Remove stats data for any namespaces that were previously
    # tracked but are no longer tracked.
    UpdateWikiNamespaceStats.clear_untracked_namespace_data(@course)
  end

  def wikidata
    @course.wikis.find { |wiki| wiki.project == 'wikidata' }
  end

  def log_update_progress(step)
    return unless debug?
    @sentry_logs ||= {}
    @sentry_logs[step] = Time.zone.now
    Sentry.capture_message "#{@course.title} update: #{step}",
                           level: 'warning',
                           extra: { logs: @sentry_logs }
  end

  def log_error(error)
    Sentry.capture_message "#{@course.title} update caches error: #{error}",
                           level: 'error'
  end

  TEN_MINUTES = 600
  def should_update_article_status?
    return true if Features.wiki_ed?
    # To cut down on overwhelming the system
    # for courses with huge numbers of articles
    # to check, we skip this on Programs & Events Dashboard
    # for slow-updating courses.
    # This means we miss cases of article deletion
    # and namespace changes unless the article
    longest_update_time(@course).to_i < TEN_MINUTES
  end

  def debug?
    @course.flags[:debug_updates]
  end
end
