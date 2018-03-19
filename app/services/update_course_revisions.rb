# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/importers/course_upload_importer"

#= Pulls in new revisions for a single course and updates the corresponding records
class UpdateCourseRevisions
  def initialize(course)
    @course = course
    fetch_data
    update_categories if @course.needs_update
    update_caches
    @course.update(needs_update: false)
  end

  private

  def fetch_data
    CourseRevisionUpdater.import_new_revisions([@course])
    CourseUploadImporter.new(@course).run
  end

  def update_categories
    Category.refresh_categories_for(@course)
  end

  def update_caches
    ArticlesCourses.update_all_caches(@course.articles_courses)
    CoursesUsers.update_all_caches(@course.courses_users)
    @course.update_cache
  end
end
