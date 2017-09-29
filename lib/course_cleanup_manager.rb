# frozen_string_literal: true

#= Class for callback cleanup methods for Courses
class CourseCleanupManager
  def initialize(course, user)
    @course = course
    @user = user
  end

  def cleanup_articles
    # find which course articles this user contributed to
    possible_deletions = course_article_ids & user_article_ids

    # have these articles been edited by other students in this course?
    to_delete = []
    possible_deletions.each do |article_id|
      to_delete.push article_id unless other_editors_in_course?(article_id)
    end

    return if to_delete.empty?

    # remove orphaned articles from the course
    @course.articles.delete(Article.find(to_delete))

    # update course cache to account for removed articles
    @course.update_cache
  end

  private

  def course_article_ids
    @course.articles.pluck(:id)
  end

  def user_article_ids
    @user.revisions
         .where('date >= ? AND date <= ?', @course.start, @course.end)
         .pluck(:article_id)
  end

  def other_editors_in_course?(article_id)
    other_editors = Article.find(article_id).editors - [@user]
    return false if other_editors.empty?
    course_editors = @course.students & other_editors
    return false if course_editors.empty?
    true
  end
end
