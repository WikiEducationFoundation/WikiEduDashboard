#= Class for callback cleanup methods for Courses
class CourseCleanupManager
  def self.cleanup_articles(course, user)
    # find which course articles this user contributed to
    user_articles = user.revisions
                    .where('date >= ? AND date <= ?', course.start, course.end)
                    .pluck(:article_id)
    course_articles = course.articles.pluck(:id)
    possible_deletions = course_articles & user_articles

    # have these articles been edited by other students in this course?
    to_delete = []
    possible_deletions.each do |pd|
      other_editors = Article.find(pd).editors - [user.id]
      course_editors = course.students & other_editors
      to_delete.push pd if other_editors.empty? || course_editors.empty?
    end

    # remove orphaned articles from the course
    course.articles.delete(Article.find(to_delete))

    # update course cache to account for removed articles
    course.update_cache unless to_delete.empty?
  end
end
