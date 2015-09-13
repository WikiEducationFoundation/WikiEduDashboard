class CourseUpdateManager
  def self.update_from_wiki(course, data={}, save=true)
    id = course.id
    if data.blank?
      data = CourseImporter.get_course_info id
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
    Dir["#{Rails.root}/lib/importers/*.rb"].each { |file| require file }

    update_from_wiki(course) if course.legacy?
    users = course.users
    articles = course.articles
    articles_courses = course.articles_courses
    courses_users = course.courses_users

    UserImporter.update_users users
    RevisionImporter.update_all_revisions course
    ViewImporter.update_views articles.namespace(0)
      .find_in_batches(batch_size: 30)
    RatingImporter.update_ratings articles.namespace(0)
      .find_in_batches(batch_size: 30)
    Article.update_all_caches articles
    User.update_all_caches users
    ArticlesCourses.update_all_caches articles_courses
    CoursesUsers.update_all_caches courses_users

    course.update_cache
  end
end
