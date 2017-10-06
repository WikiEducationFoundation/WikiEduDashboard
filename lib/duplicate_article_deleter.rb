# frozen_string_literal: true

require "#{Rails.root}/lib/modified_revisions_manager"

#= Deletes duplicate Article records that differ by ID but match by title and namespace
class DuplicateArticleDeleter
  def initialize(wiki = nil)
    wiki ||= Wiki.default_wiki
    @wiki = wiki
  end

  ###############
  # Entry point #
  ###############
  def resolve_duplicates(articles = nil)
    grouped = articles_grouped_by_title_and_namespace(articles)
    @deleted_ids = []
    grouped.each do |article_group|
      delete_duplicates_in(article_group)
    end

    # At this stage check to see if the deleted articles' revisions still exist
    # if so, move them to their new article ID
    limbo_revisions = Revision.where(article_id: @deleted_ids)
    ModifiedRevisionsManager.new(@wiki).move_or_delete_revisions limbo_revisions
  end

  #################
  # Helper method #
  #################
  private

  def articles_grouped_by_title_and_namespace(articles)
    articles ||= Article.where(deleted: false, wiki_id: @wiki.id)
    titles = articles.map(&:title)
    Article.where(title: titles, wiki_id: @wiki.id).group(%w[title namespace]).count
  end

  def delete_duplicates_in(article_group)
    return unless article_group[1] > 1
    title = article_group[0][0]
    namespace = article_group[0][1]
    Rails.logger.debug "Resolving duplicates for '#{title}, ns #{namespace}'"
    @deleted_ids += delete_duplicates(title, namespace)
  end

  # Delete all articles with the given title
  # and namespace except for the most recently created
  def delete_duplicates(title, ns)
    articles = Article.where(title: title, namespace: ns, wiki_id: @wiki.id).order(:created_at)
    keeper = articles.first
    # Here we must verify that the titles match, since searching by title is case-insensitive.
    deleted = articles.where.not(id: keeper.id).select { |article| article.title == keeper.title }
    deleted.each do |article|
      article.update(deleted: true)
    end
    deleted.map(&:id)
  end
end
