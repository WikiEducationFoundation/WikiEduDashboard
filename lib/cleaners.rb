#= Cleaners
class Cleaners
  ####################
  # Articles Courses #
  ####################
  def self.remove_bad_articles_courses
    non_student_cus = CoursesUsers.where(role: [1, 2, 3, 4])
    non_student_cus.each do |nscu|
      remove_bad_articles_courses_for_course_user nscu
    end
  end

  def self.rebuild_articles_courses(courses=nil)
    courses ||= Course.current
    courses.each do |course|
      ArticlesCourses.update_from_course(course)
    end
  end

  ############
  # Articles #
  ############
  def self.remove_bad_articles_courses_for_course_user(course_user)
    course = course_user.course
    user_id = course_user.user_id
    # Check if the non-student user is also a student in the same course.
    return if course_user.user.student?(course)

    user_articles = find_user_articles(course_user, course)
    return if user_articles.empty?

    course_articles = course.articles.pluck(:id)
    possible_deletions = course_articles & user_articles

    to_delete = []
    possible_deletions.each do |a_id|
      to_delete.push a_id unless other_editors_in_course?(a_id, user_id, course)
    end

    # remove orphaned articles from the course
    course.articles.delete(Article.find(to_delete))
    Rails.logger.info(
      "Deleted #{to_delete.size} ArticlesCourses from #{course.title}"
    )
    # update course cache to account for removed articles
    course.update_cache unless to_delete.empty?
  end

  def self.other_editors_in_course?(article_id, user_id, course)
    other_editors = Article.find(article_id).editors - [user_id]
    return false if other_editors.empty?
    course_editors = course.students & other_editors
    return false if course_editors.empty?
    true
  end

  def self.find_user_articles(course_user, course)
    course_user
      .user.revisions
      .where('date >= ?', course.start)
      .where('date <= ?', course.end)
      .pluck(:article_id)
  end

  ###############
  # Assignments #
  ###############
  def self.match_assignment_titles_with_case_variant_articles_that_exist(count=nil)
    require "#{Rails.root}/lib/article_utils"

    assignments = Assignment.where(article_id: nil)
    assignments = assignments.last(count) if count
    assignments.each do |assignment|
      possibly_bad_title = assignment.article_title
      next unless possibly_bad_title == ArticleUtils.format_article_title(possibly_bad_title.downcase)
      title_search_result = first_article_search_result(assignment.wiki, possibly_bad_title)
      next if possibly_bad_title == title_search_result
      next unless title_search_result.downcase == possibly_bad_title.downcase.tr(' ', '_')
      assignment.article_title = title_search_result
      assignment.save
    end
  end

  def self.first_article_search_result(wiki, search_term)
    require "#{Rails.root}/lib/wiki_api"
    query = { list: 'search',
              srsearch: search_term,
              srnamespace: 0,
              srlimit: 1 }
    response = WikiApi.new(wiki).query(query)
    return '' if response.nil?
    results = response.data['search']
    return '' if results.empty?
    results = results[0]['title'].tr(' ', '_')
    results
  end
end
