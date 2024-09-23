# frozen_string_literal: true

#= Cleaner for ArticlesCourses that are not part of a course anymore.
# This class has to be renamed to ArticlesCoursesCleaner when deleting
# the existing ArticlesCoursesCleaner class.
class ArticlesCoursesCleanerTimeslice
  ################
  # Entry points #
  ################

  def self.clean_articles_courses_for_wiki_ids(course, wiki_ids)
    new(course).remove_articles_courses_for_wiki_ids(wiki_ids)
  end

  def self.clean_articles_courses_for_user_ids(course, user_ids)
    new(course).remove_articles_courses_for_user_ids(user_ids)
  end

  def initialize(course)
    @course = course
  end

  # Removes the articles courses records belonging to articles in the given wiki ids.
  # We need to call this method when a tracked wiki is removed from a course.
  def remove_articles_courses_for_wiki_ids(wiki_ids)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles.where(wiki_id: wiki_ids).pluck(:id)

    # Collect the ids of articles courses to be deleted
    articles_courses_ids = ArticlesCourses.where(course_id: @course.id,
                                                 article_id: article_ids).pluck(:id)

    return if articles_courses_ids.empty?

    # Do this in batches to avoid running the MySQL server out of memory
    articles_courses_ids.each_slice(5000) do |slice|
      ArticlesCourses.where(id: slice).delete_all
    end
    Rails.logger.info "Deleted #{articles_courses_ids.size} ArticlesCourses from #{@course.title}"
  end

  # Removes the articles courses records that were edited only by users that got disenrolled
  # from the course.
  # We need to call this method when a course user is removed from a course.
  def remove_articles_courses_for_user_ids(user_ids)
    articles_courses = user_ids.map do |user_id|
      # Get all the articles courses edited by the user
      ArticlesCourses.search_by_course_and_user(@course, user_id)
    end.flatten.uniq

    to_delete = articles_courses.select do |article_course|
      # Only delete articles courses if every editor in that article was removed
      # articles_courses unless
      article_course.user_ids.all? { |editor| user_ids.include?(editor) }
    end.flatten

    to_delete.each_slice(5000) do |slice|
      ArticlesCourses.where(id: slice.map(&:id)).delete_all
      ArticleCourseTimeslice.where(course: @course, article_id: slice.map(&:article_id)).delete_all
    end
    Rails.logger.info "Deleted #{to_delete.size} ArticlesCourses from #{@course.title}"
  end
end
