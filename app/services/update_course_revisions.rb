# frozen_string_literal: true

require "#{Rails.root}/lib/course_revision_updater"

#= Pulls in new revisions for a single course and updates the corresponding records
class UpdateCourseRevisions
  def initialize(course)
    @course = course
    fetch_data
    update_caches
  end

  private

  def fetch_data
    CourseRevisionUpdater.import_new_revisions([@course])
  end

  def update_caches
    ArticlesCourses.update_all_caches(@course.articles_courses)
    CoursesUsers.update_all_caches(@course.courses_users)
    @course.update_cache
  end
end
