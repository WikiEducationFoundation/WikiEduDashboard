require "#{Rails.root}/lib/importers/revision_importer"

#= Deletes duplicate Article records that differ by ID but match by title and namespace
class DuplicateArticleDeleter
  ###############
  # Entry point #
  ###############
  def self.resolve_duplicates(articles = nil)
    articles ||= Article.where(deleted: false)
    titles = articles.map(&:title)
    # TODO: group by wiki
    grouped = Article.where(title: titles).group(%w(title namespace)).count
    deleted_ids = []
    grouped.each do |article|
      next unless article[1] > 1
      title = article[0][0]
      namespace = article[0][1]
      Rails.logger.debug "Resolving duplicates for '#{title}, ns #{namespace}'"
      deleted_ids += delete_duplicates Wiki.default_wiki, title, namespace
    end

    # At this stage check to see if the deleted articles' revisions still exist
    # if so, move them to their new article ID
    limbo_revisions = Revision.where(article_id: deleted_ids)
    RevisionImporter.move_or_delete_revisions limbo_revisions
  end

  #################
  # Helper method #
  #################

  # Delete all articles with the given title
  # and namespace except for the most recently created
  def self.delete_duplicates(wiki, title, ns)
    articles = Article.where(title: title, namespace: ns).order(:created_at)
    deleted = articles.where.not(id: articles.last.id)
    deleted.update_all(deleted: true)
    deleted.map(&:id)
  end
end
