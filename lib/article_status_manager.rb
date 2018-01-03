# frozen_string_literal: true

require "#{Rails.root}/lib/modified_revisions_manager"

#= Updates articles to reflect deletion and page moves on Wikipedia
class ArticleStatusManager
  def initialize(wiki = nil)
    @wiki = wiki || Wiki.default_wiki
  end

  ###############
  # Entry point #
  ###############

  # Queries deleted state and namespace for all articles
  def self.update_article_status
    threads = Course.current
                    .in_groups(Replica::CONCURRENCY_LIMIT, false)
                    .map.with_index do |course_batch, i|
      Thread.new(i) do
        course_batch.each do |course|
          update_article_status_for_course(course)
        end
      end
    end
    threads.each(&:join)
  end

  #################
  # Class helpers #
  #################
  def self.update_article_status_for_course(course)
    course_articles = course.pages_edited
    Wiki.all.each do |wiki|
      articles = course_articles.where(wiki_id: wiki.id)
      next if articles.empty?
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
    update_deleted_articles(articles)
    update_undeleted_articles(articles)
    ArticlesCourses.where(article_id: @deleted_page_ids).destroy_all
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
      article = Article.find_by(wiki_id: @wiki.id, mw_page_id: article_data['page_id'])
      next if data_matches_article?(article_data, article)
      article.update!(title: article_data['page_title'],
                      namespace: article_data['page_namespace'],
                      deleted: false)
    end
  end

  def update_deleted_articles(articles)
    return unless @failed_request_count.zero?
    articles.where(mw_page_id: @deleted_page_ids).each do |article|
      article.update_attribute(:deleted, true)
    end
  end

  def update_undeleted_articles(articles)
    articles.where(mw_page_id: @synced_ids).each do |article|
      article.update_attribute(:deleted, false)
    end
  end

  def data_matches_article?(article_data, article)
    return false unless article.title == article_data['page_title']
    return false unless article.namespace == article_data['page_namespace'].to_i
    # If article data is collected from Replica, the article is not currently deleted
    return false if article.deleted
    true
  end

  # This is limited by the URI length of the combined titles. For most languages,
  # 100 titles per query is no problem, but languages with unicode titles hit the
  # URI length limit.
  # TODO: move the chunking to Replica and set the size dynamically depending on the
  # length of the URI.
  LONG_URI_LANGUAGES = %w(he ar ml mk).freeze
  HIGH_REPLICA_LIMIT = 80
  LOW_REPLICA_LIMIT = 20
  def articles_per_replica_query
    LONG_URI_LANGUAGES.include?(@wiki.language) ? LOW_REPLICA_LIMIT : HIGH_REPLICA_LIMIT
  end

  # Check whether any deleted pages still exist with a different article_id.
  # If so, update the Article to use the new id.
  def update_article_ids(deleted_page_ids)
    maybe_deleted = Article.where(mw_page_id: deleted_page_ids, wiki_id: @wiki.id)

    # These pages have titles that match Articles in our DB with deleted ids
    same_title_pages = Utils.chunk_requests(maybe_deleted, articles_per_replica_query) do |block|
      request_results = Replica.new(@wiki).get_existing_articles_by_title block
      @failed_request_count += 1 if request_results.nil?
      request_results
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

    article = Article.find_by(wiki_id: @wiki.id, title: title, namespace: namespace, deleted: false)

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
    if Article.exists?(mw_page_id: mw_page_id, wiki_id: @wiki.id)
      # Catches case where update_constantly has
      # already added this article under a new ID
      article.update(deleted: true)
    else
      article.update(mw_page_id: mw_page_id)
    end
  end
end
