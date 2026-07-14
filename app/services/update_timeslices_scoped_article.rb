# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/timeslice_cleaner"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner"

# Adjusts timeslices when articles enter or leave scope in ArticleScopedProgram
# and VisitingScholarship courses.
#
# ACUWT path (course.use_acuwt? == true):
#   New articles (scoped, no articles_courses, but ACUWT rows exist from a prior update
#   when they were unscoped — those rows have revision data but zero references_count
#   and no wikidata stats): creates the articles_courses records and marks the ACUWT
#   rows as needs_update, so ReprocessArticleCourseUserWikiTimeslices re-scores them
#   and reaggregates the affected timeslices later in the same update. This is the
#   same mechanism used when an article moves into a tracked namespace (see
#   ArticlesCourses.update_from_course_revisions).
#
#   Old articles (articles_courses present but no longer scoped): removes the
#   articles_courses and ACUWT rows, then marks affected CWT timeslices for reaggregation.
#
# Legacy path (course.use_acuwt? == false):
#   Both cases are handled by ArticlesCoursesCleaner, marking CWT timeslices
#   as needs_update for a full re-fetch.
class UpdateTimeslicesScopedArticle
  def initialize(course, update_service: nil)
    @course = course
    @timeslice_cleaner = TimesliceCleaner.new(course)
    @scoped_article_ids = course.scoped_article_ids
    @update_service = update_service
  end

  def run
    return unless @course.only_scoped_articles_course?

    if @course.use_acuwt?
      handle_new_articles_acuwt
      handle_old_articles_acuwt
    else
      handle_new_articles_legacy
      handle_old_articles_legacy
    end
  end

  private

  ###############
  # ACUWT paths #
  ###############

  def handle_new_articles_acuwt
    new_article_ids = tracked_article_ids(new_article_ids_with_acuwt_rows)
    return if new_article_ids.empty?

    log_info "Adding new scoped articles: #{new_article_ids}"
    ArticlesCourses.create_records_and_mark_acuwt(@course, new_article_ids)
  end

  def handle_old_articles_acuwt
    old_article_ids = unscoped_article_ids
    return if old_article_ids.empty?

    log_info "Removing old unscoped articles: #{old_article_ids}"

    acuwt = ArticleCourseUserWikiTimeslice.where(course: @course, article_id: old_article_ids)
    @timeslice_cleaner.reset_timeslices_for_reaggregation_from_acuwt(acuwt)
    ArticlesCourses.where(course: @course, article_id: old_article_ids).delete_all
  end

  # Scoped article IDs that lack articles_courses records but have existing ACUWT rows
  # (created when the articles were unscoped and scores were not fetched).
  def new_article_ids_with_acuwt_rows
    tracked_ids = @course.articles_courses
                         .where(article_id: @scoped_article_ids)
                         .pluck(:article_id)
    untracked_scoped_ids = @scoped_article_ids - tracked_ids
    return [] if untracked_scoped_ids.empty?

    ArticleCourseUserWikiTimeslice
      .where(course: @course, article_id: untracked_scoped_ids)
      .distinct.pluck(:article_id)
  end

  ################
  # Legacy paths #
  ################

  def handle_new_articles_legacy
    articles_with_timeslices = @course.article_course_timeslices
                                      .where(article_id: @scoped_article_ids)
                                      .pluck(:article_id)
    tracked_articles = @course.articles_courses
                              .where(article_id: @scoped_article_ids)
                              .pluck(:article_id)
    reset_legacy(articles_with_timeslices - tracked_articles)
  end

  def handle_old_articles_legacy
    reset_legacy(unscoped_article_ids)
  end

  def reset_legacy(article_ids)
    return if article_ids.empty?

    log_info "Resetting #{article_ids}"

    articles = Article.where(id: article_ids)
    ArticlesCoursesCleaner.reset_specific_articles(@course, articles)
  end

  ###########
  # Helpers #
  ###########

  def unscoped_article_ids
    @course.articles_courses
           .where.not(article_id: @scoped_article_ids)
           .pluck(:article_id)
  end

  # Only articles in tracked wikis and namespaces get articles_courses records.
  # Scoped article ids are linked to mainspace articles, but may point to non-mainspace
  # articles later: assignments keep their article_id when the article moves to another
  # namespace (see AssignmentUpdater). Without this filter, such articles would get their
  # articles_courses record created here and deleted by ArticleNamespacesManager on
  # every update.
  def tracked_article_ids(article_ids)
    return [] if article_ids.empty?
    @course.tracked_namespaces.flat_map do |wiki_ns|
      Article.where(id: article_ids, wiki: wiki_ns[:wiki], namespace: wiki_ns[:namespace])
             .pluck(:id)
    end
  end

  def log_info(message)
    Rails.logger.info "UpdateTimeslicesScopedArticle: Course: #{@course.slug} #{message}"
  end
end
