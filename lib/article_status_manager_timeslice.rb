# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"
require_dependency "#{Rails.root}/lib/assignment_updater"

#= Updates articles to reflect deletion and page moves on Wikipedia
# This class is responsible for two main things (we may separate it in the future).
# - Iterate over article course timeslices to sync articles. This updates title,
# namespace, deleted and mw_page_id fields.
# - Reset articles according to their new status:
#   * Articles that were deleted or untracked. These are articles that were either
#   deleted or moved to a namespace not traceable by the course. Such articles
#   should be excluded from course statistics.
#   * Articles that were restored or re-tracked: These are articles that were
#   either undeleted or moved to a namespace relevant to the course. Such articles
#   should be included in course statistics.
#   TODO: this class can probably be made simpler

class ArticleStatusManagerTimeslice
  def initialize(course, wiki = nil)
    @course = course
    @wiki = wiki || Wiki.default_wiki
  end

  ################
  # Entry points #
  ################

  def self.update_article_status_for_course(course)
    course.wikis.each do |wiki|
      # Retrieve articles based on ac timeslices to also include current untracked articles.
      course.articles_from_timeslices(wiki.id)
            # Updating only those articles which are updated more than 1 day ago
            .where('articles.updated_at < ?', 1.day.ago)
            .in_batches do |article_batch|
        # Using in_batches so that the update_at of all articles in the batch can be
        # excuted in a single query, otherwise if we use find_in_batches, query for
        # each article for updating the same would be required
        new(course, wiki).update_status(article_batch)
        # rubocop:disable Rails/SkipsModelValidations
        article_batch.touch_all(:updated_at)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    ArticlesCoursesCleanerTimeslice.reset_articles_for_course(course)
  end

  ####################
  # Per-wiki methods #
  ####################

  def update_status(articles)
    # This is used for problem cases where articles can't be easily disambiguated
    # because of duplicate records with the same mw_page_id. It's only used if
    # `articles` is just one record.
    @article = articles.first if articles.one?

    identify_deleted_and_synced_page_ids(articles)

    # First we find any pages that just moved, and update title and namespace.
    update_title_and_namespace @synced_articles

    # Now we check for pages that have changed mw_page_ids.
    # This happens in situations such as history merges.
    # If articles move in between title/namespace updates and mw_page_id updates,
    # then it's possible to end up with inconsistent data.
    update_article_ids @deleted_page_ids

    # Mark articles as deleted as appropriate
    update_deleted_articles(articles)
    move_timeslices_for_deleted_articles(articles)
  end

  ##################
  # Helper methods #
  ##################
  private

  def identify_deleted_and_synced_page_ids(articles)
    @synced_articles = article_data_from_replica(articles)
    @synced_ids = @synced_articles.map { |a| a['page_id'].to_i }

    # If any Replica requests failed, we don't want to assume that missing
    # articles are deleted.
    # FIXME: A better approach would be to look for deletion logs, and only mark
    # an article as deleted if there is a corresponding deletion log.
    @deleted_page_ids = if @failed_request_count.zero?
                          articles.map(&:mw_page_id) - @synced_ids
                        else
                          []
                        end
  end

  def article_data_from_replica(articles)
    @failed_request_count = 0
    synced_articles = Utils.chunk_requests(articles, 100) do |block|
      request_results = Replica.new(@wiki).get_existing_articles_by_id block
      @failed_request_count += 1 if request_results.nil?
      request_results
    end
    synced_articles
  end

  def update_title_and_namespace(synced_articles)
    # Update titles and namespaces based on mw_page_ids
    synced_articles.each do |article_data|
      article = @article || find_article_by_mw_page_id(article_data['page_id'])
      next if data_matches_article?(article_data, article)

      # FIXME: Workaround for four-byte unicode characters in article titles,
      # until we fix the database to handle them.
      # https://github.com/WikiEducationFoundation/WikiEduDashboard/issues/1744
      # These titles are saved as their URL-encoded equivalents.
      next if article.title[0] == '%'

      begin
        article.update!(title: article_data['page_title'],
                        namespace: article_data['page_namespace'],
                        deleted: false)
        # Find corresponding Assignment records and update the titles
        AssignmentUpdater.update_assignments_for_article(article)
      rescue ActiveRecord::RecordNotUnique => e
        # If we reach this point, it's most likely that @article has been set. This only
        # happens when update_status is invoked with a single article, which probably indicates
        # it was called from a cleanup script. In this case, we consider @article as
        # a duplicate article record, so we re-process timeslices for it.

        # If this is a duplicate article record, moving the revisions to the non-deleted
        # copy should prevent it from being part of a future update.
        # NOTE: ActiveRecord::RecordNotUnique is a subtype of ActiveRecord::StatementInvalid
        # so this rescue comes first.
        handle_undeletion(article)
        Sentry.capture_exception e, level: 'warning'
      rescue ActiveRecord::StatementInvalid => e # workaround for 4-byte unicode errors
        Sentry.capture_exception e
      end
    end
  end

  def update_deleted_articles(articles)
    return unless @failed_request_count.zero?
    articles.each do |article|
      next unless @deleted_page_ids.include? article.mw_page_id
      # Reload to account for articles that have had their mw_page_id changed
      # because the page was moved rather than deleted.
      next unless @deleted_page_ids.include? article.reload.mw_page_id
      article.update(deleted: true)
    end
  end

  # If an article sets as deleted has a sync mw page id, then mark the timeslices
  # as needs_update
  def move_timeslices_for_deleted_articles(articles)
    articles.filter(&:deleted).each do |article|
      next unless @synced_ids.include? article.mw_page_id
      handle_undeletion(article)
    end
  end

  def handle_undeletion(article)
    # If there's already a non-deleted copy, we need to reprocess the timeslices for article
    nondeleted_article = Article.find_by(wiki_id: @wiki.id,
                                         mw_page_id: article.mw_page_id, deleted: false)
    # If there is only one copy of the article, it was already found and updated
    # via `update_title_and_namespace`
    return unless nondeleted_article
    ArticlesCoursesCleanerTimeslice.reset_specific_articles(@course, [article])
  end

  def data_matches_article?(article_data, article)
    return false unless article.title == article_data['page_title']
    return false unless article.namespace == article_data['page_namespace'].to_i
    # If article data is collected from Replica, the article is not currently deleted
    return false if article.deleted
    true
  end

  # Check whether any deleted pages still exist with a different article_id.
  # If so, update the Article to use the new id.
  def update_article_ids(deleted_page_ids)
    maybe_deleted = Article.where(mw_page_id: deleted_page_ids, wiki_id: @wiki.id)
    return if maybe_deleted.empty?
    # These pages have titles that match Articles in our DB with deleted ids
    request_results = Replica.new(@wiki).post_existing_articles_by_title maybe_deleted
    @failed_request_count += 1 if request_results.nil?

    # Update articles whose IDs have changed (keyed on title and namespace)
    request_results&.each do |stp|
      resolve_page_id(stp, deleted_page_ids)
    end
  end

  def resolve_page_id(same_title_page, deleted_page_ids)
    title = same_title_page['page_title']
    mw_page_id = same_title_page['page_id']
    namespace = same_title_page['page_namespace']

    article = Article.find_by(wiki_id: @wiki.id, title:, namespace:, deleted: false)

    return unless article_data_matches?(article, title, deleted_page_ids)
    update_article_page_id(article, mw_page_id)
  end

  def article_data_matches?(article, title, deleted_page_ids)
    return false if article.nil?
    return false unless deleted_page_ids.include?(article.mw_page_id)
    # This catches false positives when the query for page_title matches
    # a case variant.
    return false unless article.title == title
    true
  end

  def update_article_page_id(article, mw_page_id)
    if Article.exists?(mw_page_id:, wiki_id: @wiki.id)
      # Catches case where update_constantly has
      # already added this article under a new ID
      article.update(deleted: true)
    else
      article.update(mw_page_id:)
    end
  end

  def find_article_by_mw_page_id(mw_page_id)
    article = Article.find_by(wiki_id: @wiki.id, mw_page_id:, deleted: false)
    article ||= Article.find_by(wiki_id: @wiki.id, mw_page_id:)
    article
  end
end
