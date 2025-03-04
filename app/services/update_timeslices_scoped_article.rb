# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"
require_dependency "#{Rails.root}/lib/revision_data_manager"

# Set as 'needs_update' timeslices associated to new scoped articles
# or to articles that are not scoped anymore due to changes in assignments
# and categories.
# Only for ArticleScopedProgram and VisitingScholarship courses
class UpdateTimeslicesScopedArticle
  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
    @scoped_article_ids = course.scoped_article_ids
  end

  def run
    return unless %w[ArticleScopedProgram VisitingScholarship].include? @course.type
    # Get the scoped articles that don't have articles courses but do have ac timeslices
    articles_with_timeslices = @course.article_course_timeslices
                                      .where(article_id: @scoped_article_ids)
                                      .pluck(:article_id)

    tracked_articles = @course.articles_courses
                              .where(article_id: @scoped_article_ids)
                              .pluck(:article_id)

    new_articles = articles_with_timeslices - tracked_articles
    reset(new_articles)

    # Get not-scoped articles with article course records
    old_articles = @course.articles_courses
                          .where.not(article_id: @scoped_article_ids)
                          .pluck(:article_id)

    reset(old_articles)
  end

  private

  def reset(article_ids)
    return if article_ids.empty?

    Rails.logger.info "UpdateTimeslicesScopedArticle: Course: #{@course.slug}\
    Resetting #{article_ids}"

    # Mark course wiki timeslices to be re-proccesed
    articles = Article.where(id: article_ids)
    ArticlesCoursesCleanerTimeslice.reset_specific_articles(@course, articles)
  end
end
