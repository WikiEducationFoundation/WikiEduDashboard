# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/article_status_manager"
require_dependency "#{Rails.root}/lib/importers/course_upload_importer"
require_dependency "#{Rails.root}/lib/data_cycle/update_logger"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"
require_dependency "#{Rails.root}/lib/importers/revision_score_importer"
require_dependency "#{Rails.root}/lib/importers/average_views_importer"
require_dependency "#{Rails.root}/lib/errors/update_service_error_helper"

#= Pulls in new revisions for a single course and updates the corresponding records
class UpdateCourseStats
  include UpdateServiceErrorHelper

  def initialize(course, full: false)
    @course = course
    # If the upate was explicitly requested by a user,
    # it could be because the dates or other paramters were just changed.
    # In that case, do a full update rather than just fetching the most
    # recent revisions.
    @full_update = full || @course.needs_update

    @start_time = Time.zone.now
    fetch_data
    update_categories
    update_article_status if @course.needs_update
    update_average_pageviews
    update_caches
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
    CourseRevisionUpdater.import_revisions(@course, all_time: @full_update, update_service: self)
    log_update_progress :revisions_imported

    RevisionScoreImporter.update_revision_scores_for_course(@course, update_service: self)
    log_update_progress :revision_scores_imported

    CourseUploadImporter.new(@course, update_service: self).run
    log_update_progress :uploads_imported
  end

  def update_categories
    Category.refresh_categories_for(@course)
    log_update_progress :categories_updated
  end

  def update_article_status
    ArticleStatusManager.update_article_status_for_course(@course)
    log_update_progress :article_status_updated
  end

  def update_average_pageviews
    AverageViewsImporter.update_outdated_average_views(@course.articles)
  end

  def update_caches
    ArticlesCourses.update_all_caches(@course.articles_courses)
    log_update_progress :articles_courses_updated
    CoursesUsers.update_all_caches(@course.courses_users)
    log_update_progress :courses_users_updated
    @course.update_cache
    HistogramPlotter.delete_csv(course: @course) # clear cached structural completeness data
    log_update_progress :course_cache_updated
  end

  def log_update_progress(step)
    return unless debug?
    @sentry_logs ||= {}
    @sentry_logs[step] = Time.zone.now
    Raven.capture_message "#{@course.title} update: #{step}",
                          level: 'warn',
                          extra: { logs: @sentry_logs }
  end

  def debug?
    @course.flags[:debug_updates]
  end
end
