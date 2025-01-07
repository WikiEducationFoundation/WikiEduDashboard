# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"

#= Cleaner for ArticlesCourses that are not part of a course anymore.
# This class has to be renamed to ArticlesCoursesCleaner when deleting
# the existing ArticlesCoursesCleaner class.
class ArticlesCoursesCleanerTimeslice # rubocop:disable Metrics/ClassLength
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

  def self.clean_articles_courses_after_course_end(course)
    new(course).remove_articles_courses_for_dates_after_end_date
  end

  # Reset articles involves the following actions:
  # - Mark timeslices for those articles as needs_update
  # - Remove article course records for those articles (if they exist)
  # - Remove article course timeslices for those articles
  def self.reset_articles_for_course(course)
    cleaner = new(course)
    cleaner.reset_deleted_or_untracked_articles
    cleaner.reset_undeleted_or_retracked_articles
  end

  def self.reset_specific_articles(course, articles)
    new(course).reset(articles)
  end

  def initialize(course)
    @course = course
  end

  # Removes the articles courses records belonging to articles in the given wiki ids.
  # We need to call this method when a tracked wiki is removed from a course.
  def remove_articles_courses_for_wiki_ids(wiki_ids)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles.where(wiki_id: wiki_ids).pluck(:id)

    return if article_ids.empty?

    delete_article_course(article_ids)
    Rails.logger.info "Deleted #{article_ids.size} ArticlesCourses from #{@course.title}"
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

    delete_article_course(article_ids_to_delete)

    # NOTE: this could be implemented in the TimesliceManager class

    # Delete article course timeslices for deleted articles
    timeslice_ids = ArticleCourseTimeslice.where(course: @course)
                                          .where(article_id: article_ids_to_delete)
                                          .pluck(:id)

    delete_article_course_timeslice_ids(timeslice_ids)

    # Delete article course timeslices for dates prior to the course start date
    timeslice_ids = ArticleCourseTimeslice.where(course: @course)
                                          .where('end <= ?', @course.start)
                                          .pluck(:id)

    delete_article_course_timeslice_ids(timeslice_ids)
  end

  def remove_articles_courses_for_dates_after_end_date
    # Articles to be deleted are those that were edited only after the current end date
    article_ids_to_delete = article_ids_edited_after_end - article_ids_edited_before_end

    delete_article_course(article_ids_to_delete)

    # NOTE: this could be implemented in the TimesliceManager class

    # Delete article course timeslices for deleted articles
    timeslice_ids = ArticleCourseTimeslice.where(course: @course)
                                          .where(article_id: article_ids_to_delete)
                                          .pluck(:id)

    delete_article_course_timeslice_ids(timeslice_ids)

    # Delete article course timeslices for dates after the course end date
    timeslice_ids = ArticleCourseTimeslice.where(course: @course)
                                          .where('start > ?', @course.end)
                                          .pluck(:id)

    delete_article_course_timeslice_ids(timeslice_ids)
  end

  # Removes the articles courses and timeslices records for article ids.
  def remove_articles_courses_for_article_ids(article_ids)
    delete_article_course(article_ids)
    timeslices = ArticleCourseTimeslice.where(course: @course).where(article_id: article_ids)
    delete_article_course_timeslice_ids(timeslices.pluck(:id))
  end

  def reset_deleted_or_untracked_articles
    # Note that this could remove articles courses records for manually untracked articles
    # Find articles with an articles_courses record but without a non-deleted article record.
    @course.articles.where(deleted: true).in_batches do |article_batch|
      reset(article_batch)
    end

    @course.articles.in_batches do |article_batch|
      tracked = @course.tracked_namespaces.each.flat_map do |wiki_ns|
        wiki_id = wiki_ns[:wiki].id
        namespace = wiki_ns[:namespace]
        article_batch.where(wiki_id:, namespace:).pluck(:id)
      end
      # Find articles with articles_courses records but not in tracked namespaces
      untracked_articles = article_batch.where.not(id: tracked)
      reset(untracked_articles)
    end
  end

  def reset_undeleted_or_retracked_articles
    @course.wikis.each do |wiki|
      # Find non-deleted and tracked articles without an articles_courses record
      @course.articles_from_timeslices(wiki.id)
             .where(deleted: false).in_batches do |article_batch|
        tracked = @course.tracked_namespaces.flat_map do |wiki_ns|
          wiki_id = wiki_ns[:wiki].id
          namespace = wiki_ns[:namespace]
          article_batch.where(wiki_id:, namespace:)
        end

        tracked_without_articles_courses = tracked - @course.articles.to_a
        reset(tracked_without_articles_courses)
      end
    end
  end

  def reset(articles)
    mark_as_needs_update(articles)
    remove_articles_courses_for_article_ids(articles.pluck(:id))
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

  # Returns article ids for every article edited after the current course end date
  def article_ids_edited_after_end
    ArticleCourseTimeslice.where(course: @course)
                          .where('start > ?', @course.end)
                          .where.not(user_ids: nil)
                          .distinct
                          .pluck(:article_id)
  end

  # Returns article ids for every article edited before the current course end date
  def article_ids_edited_before_end
    ArticleCourseTimeslice.where(course: @course)
                          .where('end <= ?', @course.end)
                          .where.not(user_ids: nil)
                          .distinct
                          .pluck(:article_id)
  end

  def delete_article_course(article_ids)
    article_ids.each_slice(5000) do |slice|
      ArticlesCourses.where(course: @course).where(article_id: slice).delete_all
    end
  end

  def delete_article_course_timeslice_ids(ids)
    ids.each_slice(5000) do |slice|
      ArticleCourseTimeslice.where(id: slice).delete_all
    end
  end

  def mark_as_needs_update(article_batch)
    timeslices = @course.article_course_timeslices.where(article: article_batch)
    timeslice_manager = TimesliceManager.new(@course)
    timeslice_manager.update_timeslices_that_need_update_from_article_timeslices(
      timeslices
    )
  end
end
