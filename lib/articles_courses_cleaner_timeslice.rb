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

  def self.clean_articles_courses_prior_to_course_start(course)
    new(course).remove_articles_courses_for_dates_prior_to_start_date
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

  def remove_articles_courses_for_dates_prior_to_start_date
    # Articles to be deleted are those that were edited only before the current start date
    article_ids_to_delete = article_ids_edited_beofre_start - article_ids_edited_after_start

    article_ids_to_delete.each_slice(5000) do |id_slice|
      ArticlesCourses.where(article_id: id_slice).delete_all
    end

    # NOTE: this could be implemented in the TimesliceManager class

    # Delete article course timeslices for deleted articles
    timeslice_ids = ArticleCourseTimeslice.where(course: @course)
                                          .where(article_id: article_ids_to_delete)
                                          .pluck(:id)

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      ArticleCourseTimeslice.where(id: timeslice_id_slice).delete_all
    end

    # Delete article course timeslices for dates prior to the course start date
    timeslice_ids = ArticleCourseTimeslice.where(course: @course)
                                          .where('end <= ?', @course.start)
                                          .pluck(:id)

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      ArticleCourseTimeslice.where(id: timeslice_id_slice).delete_all
    end
  end

  private

  # Returns article ids for every article edited before the current course start date
  def article_ids_edited_beofre_start
    ArticleCourseTimeslice.where(course: @course)
                          .where('end <= ?', @course.start)
                          .where.not(user_ids: nil)
                          .distinct
                          .pluck(:article_id)
  end

  # Returns article ids for every article edited before the current course start date
  def article_ids_edited_after_start
    ArticleCourseTimeslice.where(course: @course)
                          .where('start >= ?', @course.start)
                          .where.not(user_ids: nil)
                          .distinct
                          .pluck(:article_id)
  end
end
