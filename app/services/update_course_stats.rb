# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/article_status_manager"
require_dependency "#{Rails.root}/lib/importers/course_upload_importer"
require_dependency "#{Rails.root}/lib/data_cycle/update_logger"

#= Pulls in new revisions for a single course and updates the corresponding records
class UpdateCourseStats
  def initialize(course)
    @course = course
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
    CourseRevisionUpdater.import_new_revisions([@course])
    CourseUploadImporter.new(@course).run
  end

  def update_categories
    Category.refresh_categories_for(@course)
  end

  def update_article_stats
    ArticleStatusManager.update_article_status_for_course(@course)
  end

  def update_caches
    ArticlesCourses.update_all_caches(@course.articles_courses)
    CoursesUsers.update_all_caches(@course.courses_users)
    @course.update_cache
  end
end
