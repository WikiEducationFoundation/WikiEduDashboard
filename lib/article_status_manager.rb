# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/modified_revisions_manager"
require_dependency "#{Rails.root}/lib/assignment_updater"
require_dependency "#{Rails.root}/lib/alerts/course_alert_manager"

#= Updates articles to reflect deletion and page moves on Wikipedia
class ArticleStatusManager
  def initialize(wiki = nil)
    @wiki = wiki || Wiki.default_wiki
  end

  ################
  # Entry points #
  ################

  def self.update_article_status_for_course(course)
    course.wikis.each do |wiki|
      # Updating only those articles which are updated more than  1 day ago
      course.pages_edited
            .where(wiki_id: wiki.id)
            .where('articles.updated_at < ?', 1.day.ago)
            .in_batches do |article_batch|
        # Using in_batches so that the update_at of all articles in the batch can be
        # excuted in a single query, otherwise if we use find_in_batches, query for
        # each article for updating the same would be required
        new(wiki).update_status(article_batch)
        # rubocop:disable Rails/SkipsModelValidations
        article_batch.touch_all(:updated_at)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
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
    CourseAlertManager.new.create_article_namespace_change_alerts

    # Now we check for pages that have changed mw_page_ids.
    # This happens in situations such as history merges.
    # If articles move in between title/namespace updates and mw_page_id updates,
    # then it's possible to end up with inconsistent data.
    update_article_ids @deleted_page_ids

    # Delete and undelete articles as appropriate
    update_deleted_articles(articles)
    update_undeleted_articles(articles)

    limbo_revisions = Revision.where(mw_page_id: @deleted_page_ids)
    ModifiedRevisionsManager.new(@wiki).move_or_delete_revisions limbo_revisions
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
        # if this is a duplicate article record, moving the revisions to the non-deleted
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

  def update_undeleted_articles(articles)
    articles.filter(&:deleted).each do |article|
      next unless @synced_ids.include? article.mw_page_id
      handle_undeletion(article)
    end
  end

  def handle_undeletion(article)
    # If there's already a non-deleted copy, we need to move the revisions to that copy.
    nondeleted_article = Article.find_by(wiki_id: @wiki.id,
                                         mw_page_id: article.mw_page_id, deleted: false)
    # If there is only one copy of the article, it was already found and updated
    # via `update_title_and_namespace`
    return unless nondeleted_article
    # rubocop:disable Rails/SkipsModelValidations
    article.revisions.update_all(article_id: nondeleted_article.id)
    # rubocop:enable Rails/SkipsModelValidations
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
