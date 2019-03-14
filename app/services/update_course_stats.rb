# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/article_status_manager"
require_dependency "#{Rails.root}/lib/importers/course_upload_importer"
require_dependency "#{Rails.root}/lib/data_cycle/update_logger"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"

#= Pulls in new revisions for a single course and updates the corresponding records
class UpdateCourseStats
  def initialize(course, full: false)
    @course = course
    # If the upate was explicitly requested by a user,
    # it could be because the dates or other paramters were just changed.
    # In that case, do a full update rather than just fetching the most
    # recent revisions.
    @full_update = full || @course.needs_update

    @start_time = Time.zone.now
    fetch_data
    update_categories if @course.needs_update
    update_article_stats if @course.needs_update
    update_caches
    @course.update(needs_update: false)
    @end_time = Time.zone.now
    UpdateLogger.update_course(@course, 'start_time' => @start_time.to_datetime,
                                        'end_time' => @end_time.to_datetime)
  end

  private

  def fetch_data
    log_update_progress :start
    CourseRevisionUpdater.import_revisions(@course, all_time: @full_update)
    log_update_progress :revisions_imported
    CourseUploadImporter.new(@course).run
    log_update_progress :uploads_imported
  end

  def update_categories
    Category.refresh_categories_for(@course)
    log_update_progress :categories_updated
  end

  def update_article_stats
    ArticleStatusManager.update_article_status_for_course(@course)
    log_update_progress :article_status_updated
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
