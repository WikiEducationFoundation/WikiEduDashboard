# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/article_status_manager_timeslice"
require_dependency "#{Rails.root}/lib/importers/course_upload_importer"
require_dependency "#{Rails.root}/lib/data_cycle/update_logger"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"
require_dependency "#{Rails.root}/lib/importers/revision_score_importer"
require_dependency "#{Rails.root}/lib/importers/average_views_importer"
require_dependency "#{Rails.root}/lib/errors/update_service_error_helper"
require_dependency "#{Rails.root}/lib/data_cycle/course_queue_sorting"
require_dependency "#{Rails.root}/lib/data_cycle/update_debugger"

#= Pulls in new revisions for a single course wiki timeslice and updates the corresponding records
class UpdateCourseStatsTimeslice
  include UpdateServiceErrorHelper
  include CourseQueueSorting

  def initialize(course)
    @course = course
    # If the upate was explicitly requested by a user,
    # it could be because the dates or other paramters were just changed.
    # In that case, do a full update rather than just fetching the most
    # recent revisions.
    @full_update = @course.needs_update
    @debugger = UpdateDebugger.new(@course)

    @start_time = Time.zone.now
    import_uploads
    update_categories
    update_article_status if should_update_article_status?
    @processed, @reprocessed = UpdateCourseWikiTimeslices.new(@course, @debugger,
                                                              update_service: self)
                                                         .run(all_time: @full_update)
    update_average_pageviews
    update_caches
    update_wikidata_stats if wikidata
    # This needs to happen after `update_caches` because it relies on ArticlesCourses#new_article
    # to calculate new article stats for each namespace.
    update_wiki_namespace_stats
    log_end_of_update
  end

  private

  def import_uploads
    @debugger.log_update_progress :start
    # TODO: note this is not wiki scoped.
    CourseUploadImporter.new(@course, update_service: self).run
    @debugger.log_update_progress :uploads_imported
  end

  def update_categories
    # TODO: note this is not wiki scoped.
    Category.refresh_categories_for(@course)
    @debugger.log_update_progress :categories_updated
  end

  def update_article_status
    ArticleStatusManagerTimeslice.update_article_status_for_course(@course)
    @debugger.log_update_progress :article_status_updated
  end

  def update_average_pageviews
    # TODO: note this is not wiki scoped.
    AverageViewsImporter.update_outdated_average_views(@course.articles)
    @debugger.log_update_progress :average_pageviews_updated
  end

  def update_caches
    ActiveRecord::Base.transaction do
      ArticlesCourses.update_required_caches_from_timeslices(@course)
      @debugger.log_update_progress :articles_courses_updated
      CoursesUsers.update_all_caches_from_timeslices(@course.courses_users)
      @debugger.log_update_progress :courses_users_updated
      @course.reload
      @course.update_cache_from_timeslices
      HistogramPlotter.delete_csv(course: @course) # clear cached structural completeness data
      @debugger.log_update_progress :course_cache_updated
    rescue StandardError => e
      log_error(e)
      raise ActiveRecord::Rollback
    end
  end

  def update_wikidata_stats
    wikidata = Wiki.get_or_create(language: nil, project: 'wikidata')
    timeslices = CourseWikiTimeslice.for_course_and_wiki(@course, wikidata)
    stats = timeslices.pluck(:stats)
    UpdateWikidataStatsTimeslice.new(@course).update_wikidata_statistics(stats)
    @debugger.log_update_progress :wikidata_stats_updated
  end

  def update_wiki_namespace_stats
    # Update each of the tracked namespaces
    @course.course_wiki_namespaces.each do |course_wiki_ns|
      wiki = course_wiki_ns.courses_wikis.wiki
      namespace = course_wiki_ns.namespace
      UpdateWikiNamespaceStatsTimeslice.new(@course, wiki, namespace)
    end
    # Remove stats data for any namespaces that were previously
    # tracked but are no longer tracked.
    UpdateWikiNamespaceStatsTimeslice.clear_untracked_namespace_data(@course)
    @debugger.log_update_progress :wiki_namespace_stats_updated
  end

  def log_end_of_update
    @course.update(needs_update: false)
    @end_time = Time.zone.now
    # TODO: improve the course flag updates
    UpdateLogger.update_course(@course, 'start_time' => @start_time.to_datetime,
                                         'end_time' => @end_time.to_datetime,
                                         'sentry_tag_uuid' => sentry_tag_uuid,
                                         'error_count' => error_count,
                                         'proccesed' => @processed,
                                         'reprocessed' => @reprocessed)
  end

  def wikidata
    @course.wikis.find { |wiki| wiki.project == 'wikidata' }
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
end
