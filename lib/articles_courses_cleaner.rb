# frozen_string_literal: true

#= Cleaner for ArticlesCourses that shouldn't be
class ArticlesCoursesCleaner
  ################
  # Entry points #
  ################
  def self.remove_bad_articles_courses
    non_student_cus = CoursesUsers.where(role: [1, 2, 3, 4])
    non_student_cus.each do |courses_user|
      new(courses_user).remove_bad_articles_courses_for_courses_user
    end
  end

  def self.rebuild_articles_courses(courses=nil)
    courses ||= Course.current
    courses.each do |course|
      ArticlesCourses.update_from_course(course)
    end
  end

  #######################
  # Main repair routine #
  #######################

  def initialize(courses_user)
    @courses_user = courses_user
    @course = courses_user.course
    @user = courses_user.user
  end

  def remove_bad_articles_courses_for_courses_user
    # Check if the non-student user is also a student in the same course.
    return if @user.student?(@course)

    # Find the records to remove
    return if user_article_ids.empty?
    identify_articles_to_remove_from_course

    # remove orphaned articles from the course
    @course.articles.delete(Article.find(@to_delete))
    Rails.logger.info "Deleted #{@to_delete.size} ArticlesCourses from #{@course.title}"

    # update course cache to account for removed articles
    @course.update_cache unless @to_delete.empty?
  end

  private

  def user_article_ids
    @user_article_ids ||= @user.revisions
                               .where('date >= ?', @course.start)
                               .where('date <= ?', @course.end)
                               .pluck(:article_id)
    @user_article_ids
  end

  def course_article_ids
    @course_article_ids ||= @course.articles.pluck(:id)
    @course_article_ids
  end

  def identify_articles_to_remove_from_course
    possible_bad_article_ids = course_article_ids & user_article_ids

    @to_delete = []
    possible_bad_article_ids.each do |article_id|
      @to_delete.push article_id unless other_editors_in_course?(article_id)
    end
  end

  def other_editors_in_course?(article_id)
    other_editors = Article.find(article_id).editors - [@user]
    return false if other_editors.empty?
    course_editors = @course.students & other_editors
    return false if course_editors.empty?
    true
  end
end
