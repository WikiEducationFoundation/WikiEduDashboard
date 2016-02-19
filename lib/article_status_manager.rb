require "#{Rails.root}/lib/importers/revision_importer"

#= Updates articles to reflect deletion and page moves on Wikipedia
# Work is broken up by wiki.
class ArticleStatusManager
  def initialize(wiki)
    @wiki = wiki
  end

  ###############
  # Entry point #
  ###############

  # Queries deleted state and namespace for all articles
  def self.update_article_status(articles=nil)
    # TODO: Narrow this down even more. Current courses, maybe?
    articles ||= Article.all

    articles.group_by(&:wiki).each do |wiki, local_articles|
      new(wiki).update_wiki_article_status local_articles
    end
  end

  def update_wiki_article_status(articles)
    failed_request_count = 0
    synced_article_data = Utils.chunk_requests(articles, 100) do |block|
      request_results = Replica.new(@wiki).get_existing_articles_by_id block
      failed_request_count += 1 if request_results.nil?
      request_results
    end
    # Build a list of articles covered by this sync.
    synced_page_ids = synced_article_data.map { |a| a['page_id'] }
    synced_articles = Article.where(native_id: synced_page_ids, wiki_id: @wiki.id)

    # If any Replica requests failed, we don't want to assume that missing
    # articles are deleted.
    # FIXME: A better approach would be to look for deletion logs, and only mark
    # an article as deleted if there is a corresponding deletion log.
    if failed_request_count == 0
      deleted_articles = articles - synced_articles
    else
      deleted_articles = []
    end

    # First we find any pages that just moved, and update title and namespace.
    update_title_and_namespace synced_articles, synced_article_data

    # Now we check for pages that have changed ids.
    # This happens in situations such as history merges.
    # If articles move in between title/namespace updates and id updates,
    # then it's possible to have an article id collision.
    update_article_ids deleted_articles

    # Delete articles as appropriate
    # TODO: update_all
    deleted_articles.each { |a| a.update(deleted: true) }
    synced_articles.each { |a| a.update(deleted: false) }
    deleted_article_ids = deleted_articles.map(&:id)
    ArticlesCourses.where(article_id: deleted_article_ids).destroy_all
    limbo_revisions = Revision.where(article_id: deleted_article_ids)
    RevisionImporter.move_or_delete_revisions limbo_revisions
  end

  ##################
  # Helper methods #
  ##################

  def update_title_and_namespace(articles, synced_article_data)
    synced_article_data.each do |sa|
      # Note that articles must be from the same wiki.
      articles.where(native_id: sa['page_id']).update_all({
        title: sa['page_title'],
        namespace: sa['page_namespace'],
        deleted: false # Accounts for the case of undeleted articles
      })
    end
  end

  # Check whether any deleted pages still exist with a different article_id.
  # If so, update the Article to use the new id.
  def update_article_ids(deleted_articles)
    # These pages have titles that match Articles in our DB with deleted ids
    same_title_pages = Utils.chunk_requests(deleted_articles, 100) do |block|
      Replica.new(@wiki).get_existing_articles_by_title block
    end

    # Update articles whose IDs have changed (keyed on title and namespace)
    same_title_pages.each do |stp|
      update_page_id(stp, deleted_articles.map(&:native_id))
    end
  end

  # Merge course articles with the same title and update page ids.
  def update_page_id(same_title_page, deleted_page_ids)
    title = same_title_page['page_title']
    page_id = same_title_page['page_id']
    namespace = same_title_page['page_namespace']

    article = Article.find_by(
      title: title,
      namespace: namespace,
      wiki_id: @wiki.id,
      deleted: false
    )
    return if article.nil?
    return unless deleted_page_ids.include?(article.native_id)
    # This catches false positives when the query for page_title matches
    # a case variant.
    return unless article.title == title

    if Article.where(native_id: page_id, wiki_id: @wiki.id).any?
      # Catches case where update_constantly has
      # already added this article under a new ID

      same_page_article = Article.find_by(native_id: page_id, wiki_id: @wiki.id)
      ArticlesCourses.where(article_id: article.id)
        .update_all(article_id: same_page_article.id)

      article.update(deleted: true)
    else
      article.update(native_id: page_id)
    end
  end
end
