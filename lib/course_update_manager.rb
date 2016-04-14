require "#{Rails.root}/lib/legacy_courses/legacy_course_updater"

#= Class for performing updates on data related to an individual Course
class CourseUpdateManager
  ################
  # Entry points #
  ################

  def self.manual_update(course)
    LegacyCourseUpdater.update_from_wiki(course) if course.legacy?

    users = course.users
    articles = course.articles
    articles_courses = course.articles_courses
    courses_users = course.courses_users

    import_course_data(course, users, articles)
    update_caches(articles, articles_courses, courses_users)

    course.update_cache
  end

  ##################
  # Helper methods #
  ##################

  def self.import_course_data(course, users, articles)
    Dir["#{Rails.root}/lib/importers/*.rb"].each { |file| require file }

    UserImporter.update_users users
    RevisionImporter.update_all_revisions course
    ViewImporter.update_views articles.namespace(0)
      .find_in_batches(batch_size: 30) unless course.legacy?
    RatingImporter.update_ratings articles.namespace(0)
      .find_in_batches(batch_size: 30)
  end

  def self.update_caches(articles, articles_courses, courses_users)
    Article.update_all_caches articles
    ArticlesCourses.update_all_caches articles_courses
    CoursesUsers.update_all_caches courses_users
  end
end
