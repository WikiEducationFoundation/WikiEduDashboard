require "#{Rails.root}/lib/importers/revision_importer"

#= Updates articles to reflect deletion and page moves on Wikipedia
class ArticleStatusManager
  def initialize(wiki = nil)
    wiki ||= Wiki.default_wiki
    @wiki = wiki
  end

  ###############
  # Entry point #
  ###############

  # Queries deleted state and namespace for all articles
  def self.update_article_status
    # TODO: Narrow this down even more. Current courses, maybe?
    Wiki.all.each do |wiki|
      articles = Article.where(wiki_id: wiki.id)
      new(wiki).update_status(articles)
    end
  end

  ####################
  # Per-wiki methods #
  ####################

  def update_status(articles)
    identify_deleted_and_synced_page_ids(articles)

    # First we find any pages that just moved, and update title and namespace.
    update_title_and_namespace @synced_articles

    # Now we check for pages that have changed mw_page_ids.
    # This happens in situations such as history merges.
    # If articles move in between title/namespace updates and mw_page_id updates,
    # then it's possible to end up with inconsistent data.
    update_article_ids @deleted_page_ids

    # Delete and undelete articles as appropriate
    articles.where(mw_page_id: @deleted_page_ids).update_all(deleted: true)
    articles.where(mw_page_id: @synced_ids).update_all(deleted: false)
    ArticlesCourses.where(article_id: @deleted_page_ids).destroy_all
    limbo_revisions = Revision.where(mw_page_id: @deleted_page_ids)
    RevisionImporter.new(@wiki).move_or_delete_revisions limbo_revisions
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
    @deleted_page_ids = if @failed_request_count == 0
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
      article = Article.find_by(wiki_id: @wiki.id, mw_page_id: article_data['page_id'])
      next if data_matches_article?(article_data, article)
      article.update!(title: article_data['page_title'],
                      namespace: article_data['page_namespace'],
                      deleted: false)
    end
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

    # These pages have titles that match Articles in our DB with deleted ids
    same_title_pages = Utils.chunk_requests(maybe_deleted, 100) do |block|
      Replica.new(@wiki).get_existing_articles_by_title block
    end

    # Update articles whose IDs have changed (keyed on title and namespace)
    same_title_pages.each do |stp|
      resolve_page_id(stp, deleted_page_ids)
    end
  end

  def resolve_page_id(same_title_page, deleted_page_ids)
    title = same_title_page['page_title']
    mw_page_id = same_title_page['page_id']
    namespace = same_title_page['page_namespace']

    article = Article.find_by(
      wiki_id: @wiki.id,
      title: title,
      namespace: namespace,
      deleted: false
    )
    return if article.nil?
    return unless deleted_page_ids.include?(article.mw_page_id)
    # This catches false positives when the query for page_title matches
    # a case variant.
    return unless article.title == title

    if Article.exists?(mw_page_id: mw_page_id, wiki_id: @wiki.id)
      # Catches case where update_constantly has
      # already added this article under a new ID
      article.update(deleted: true)
    else
      article.update(mw_page_id: mw_page_id)
    end
  end
end
