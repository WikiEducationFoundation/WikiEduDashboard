#= Class for performing updates on data related to an individual Course
class CourseUpdateManager
  ################
  # Entry points #
  ################

  def self.update_from_wiki(course, data={}, save=true)
    require "#{Rails.root}/lib/legacy_courses/legacy_course_importer"
    require "#{Rails.root}/lib/importers/user_importer"

    id = course.id
    if data.blank?
      data = LegacyCourseImporter.get_course_info id
      return if data.blank? || data[0].nil?
      data = data[0]
    end
    # Symbol if coming from controller, string if from course importer
    course.attributes = data[:course] || data['course']

    return unless save
    if data['participants']
      data['participants'].each_with_index do |(r, _p), i|
        UserImporter.add_users(data['participants'][r], i, course)
      end
    end
    course.save
  end

  def self.manual_update(course)
    update_from_wiki(course) if course.legacy?

    users = course.users
    articles = course.articles
    articles_courses = course.articles_courses
    courses_users = course.courses_users

    import_course_data(course, users, articles)
    update_caches(articles, users, articles_courses, courses_users)

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
      .find_in_batches(batch_size: 30)
    RatingImporter.update_ratings articles.namespace(0)
      .find_in_batches(batch_size: 30)
  end

  def self.update_caches(articles, users, articles_courses, courses_users)
    Article.update_all_caches articles
    User.update_all_caches users
    ArticlesCourses.update_all_caches articles_courses
    CoursesUsers.update_all_caches courses_users
  end
end
