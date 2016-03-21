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
    failed_request_count = 0
    synced_articles = Utils.chunk_requests(articles, 100) do |block|
      request_results = Replica.new(@wiki).get_existing_articles_by_id block
      failed_request_count += 1 if request_results.nil?
      request_results
    end
    synced_ids = synced_articles.map { |a| a['page_id'].to_i }

    # If any Replica requests failed, we don't want to assume that missing
    # articles are deleted.
    # FIXME: A better approach would be to look for deletion logs, and only mark
    # an article as deleted if there is a corresponding deletion log.
    if failed_request_count == 0
      deleted_page_ids = articles.map(&:mw_page_id) - synced_ids
    else
      deleted_page_ids = []
    end

    # First we find any pages that just moved, and update title and namespace.
    update_title_and_namespace synced_articles

    # Now we check for pages that have changed ids.
    # This happens in situations such as history merges.
    # If articles move in between title/namespace updates and id updates,
    # then it's possible to have an article id collision.
    update_article_ids deleted_page_ids

    # Delete articles as appropriate
    articles.where(mw_page_id: deleted_page_ids).update_all(deleted: true)
    articles.where(mw_page_id: synced_ids).update_all(deleted: false)
    ArticlesCourses.where(article_id: deleted_page_ids).destroy_all
    limbo_revisions = Revision.where(mw_page_id: deleted_page_ids)
    RevisionImporter.new(@wiki).move_or_delete_revisions limbo_revisions
  end

  ##################
  # Helper methods #
  ##################
  private

  def update_title_and_namespace(synced_articles)
    # Update titles and namespaces based on ids (we trust ids!)
    synced_articles.map! do |sa|
      Article.new(
        id: sa['page_id'],
        mw_page_id: sa['page_id'],
        title: sa['page_title'],
        namespace: sa['page_namespace'],
        wiki_id: @wiki.id,
        deleted: false # Accounts for the case of undeleted articles
      )
    end
    update_keys = [:title, :namespace, :deleted, :mw_page_id]
    Article.import synced_articles, on_duplicate_key_update: update_keys
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
    id = same_title_page['page_id']
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

    ArticlesCourses.where(article_id: article.id)
      .update_all(article_id: id)

    if Article.exists?(mw_page_id: id, wiki_id: @wiki.id)
      # Catches case where update_constantly has
      # already added this article under a new ID
      article.update(deleted: true)
    else
      # FIXME: This should only update mw_page_id once id and mw_page_id are decoupled.
      article.update(mw_page_id: id, id: id)
    end
  end
end
