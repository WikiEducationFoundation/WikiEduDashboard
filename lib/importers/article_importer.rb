require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/importers/revision_importer"

#= Imports and updates articles from Wikipedia into the dashboard database
class ArticleImporter
  ################
  # Entry points #
  ################

  ##############
  # API Access #
  ##############
  # Queries deleted state and namespace for all articles
  def self.update_article_status(articles=nil)
    # TODO: Narrow this down even more. Current courses, maybe?
    local_articles = articles || Article.all

    synced_articles = Utils.chunk_requests(local_articles, 100) do |block|
      Replica.get_existing_articles_by_id block
    end
    synced_ids = synced_articles.map { |a| a['page_id'].to_i }
    deleted_ids = local_articles.pluck(:id) - synced_ids

    # First we find any pages that just moved, and update title and namespace.
    update_title_and_namespace synced_articles

    # Now we check for pages that have changed ids.
    # This happens in situations such as history merges.
    # If articles move in between title/namespace updates and id updates,
    # then it's possible to have an article id collision.
    update_article_ids deleted_ids

    # Delete articles as appropriate
    local_articles.where(id: deleted_ids).update_all(deleted: true)
    local_articles.where(id: synced_ids).update_all(deleted: false)
    ArticlesCourses.where(article_id: deleted_ids).destroy_all
    limbo_revisions = Revision.where(article_id: deleted_ids)
    RevisionImporter.move_or_delete_revisions limbo_revisions
  end

  def self.update_title_and_namespace(synced_articles)
    # Update titles and namespaces based on ids (we trust ids!)
    synced_articles.map! do |sa|
      Article.new(
        id: sa['page_id'],
        title: sa['page_title'],
        namespace: sa['page_namespace'],
        deleted: false # Accounts for the case of undeleted articles
      )
    end
    update_keys = [:title, :namespace, :deleted]
    Article.import synced_articles, on_duplicate_key_update: update_keys
  end

  # Check whether any deleted pages still exist with a different article_id.
  # If so, update the Article to use the new id.
  def self.update_article_ids(deleted_ids)
    maybe_deleted = Article.where(id: deleted_ids)

    # These pages have titles that match Articles in our DB with deleted ids
    same_title_pages = Utils.chunk_requests(maybe_deleted, 100) do |block|
      Replica.get_existing_articles_by_title block
    end

    # Update articles whose IDs have changed (keyed on title and namespace)
    same_title_pages.each do |stp|
      resolve_article_id(stp, deleted_ids)
    end
  end

  def self.resolve_article_id(same_title_page, deleted_ids)
    title = same_title_page['page_title']
    id = same_title_page['page_id']
    namespace = same_title_page['page_namespace']

    article = Article.find_by(
      title: title,
      namespace: namespace,
      deleted: false
    )
    return if article.nil?
    return unless deleted_ids.include?(article.id)
    # This catches false positives when the query for page_title matches
    # a case variant.
    return unless article.title == title

    ArticlesCourses.where(article_id: article.id)
      .update_all(article_id: id)

    if Article.exists?(id)
      # Catches case where update_constantly has
      # already added this article under a new ID
      article.update(deleted: true)
    else
      article.update(id: id)
    end
  end

  def self.resolve_duplicate_articles(articles=nil)
    articles ||= Article.where(deleted: false)
    titles = articles.map(&:title)
    grouped = Article.where(title: titles).group(%w(title namespace)).count
    deleted_ids = []
    grouped.each do |article|
      next unless article[1] > 1
      title = article[0][0]
      namespace = article[0][1]
      Rails.logger.debug "Resolving duplicates for '#{title}, ns #{namespace}'"
      deleted_ids += delete_duplicates title, namespace
    end

    # At this stage check to see if the deleted articles' revisions still exist
    # if so, move them to their new article ID
    limbo_revisions = Revision.where(article_id: deleted_ids)
    RevisionImporter.move_or_delete_revisions limbo_revisions
  end

  def self.import_articles(ids)
    article_ids = ids.map { |id| { 'id' => id } }
    articles_data = []
    article_ids.each_slice(40) do |some_article_ids|
      articles_data += Replica.get_existing_articles_by_id some_article_ids
    end
    return if articles_data.empty?
    articles = []
    articles_data.each do |article_data|
      articles << Article.new(id: article_data['page_id'],
                              title: article_data['page_title'],
                              namespace: article_data['page_namespace'])
    end
    Article.import articles
  end

  # Delete all articles with the given title
  # and namespace except for the most recently created
  def self.delete_duplicates(title, ns)
    articles = Article.where(title: title, namespace: ns).order(:created_at)
    deleted = articles.where.not(id: articles.last.id)
    deleted.update_all(deleted: true)
    deleted.map(&:id)
  end
end
