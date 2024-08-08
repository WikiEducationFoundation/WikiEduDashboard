# frozen_string_literal: true

#= Cleaner for ArticlesCourses that are not part of a course anymore
# This class has to be renamed to ArticlesCoursesCleaner when deleting
# the existing ArticlesCoursesCleaner class.
class ArticlesCoursesCleanerTimeslice
  ################
  # Entry points #
  ################

  def self.remove_bad_articles_courses(course, wiki_ids)
    new(course).remove_bad_articles_courses_for_wiki_ids(wiki_ids)
  end

  #######################
  # Main repair routine #
  #######################

  def initialize(course)
    @course = course
  end

  def remove_bad_articles_courses_for_wiki_ids(wiki_ids)
    # Collect the ids of articles to be deleted
    article_ids = @course.articles.where(wiki_id: wiki_ids).pluck(:id)

    # Collect the ids of timeslices to be deleted
    timeslice_ids = ArticlesCourses.where(course_id: @course.id,
                                          article_id: article_ids).pluck(:id)

    return if timeslice_ids.empty?

    # Do this in batches to avoid running the MySQL server out of memory
    timeslice_ids.each_slice(5000) do |timeslice_id_slice|
      ArticlesCourses.where(id: timeslice_id_slice).delete_all
    end
    Rails.logger.info "Deleted #{timeslice_ids.size} ArticlesCourses from #{@course.title}"
  end
end
