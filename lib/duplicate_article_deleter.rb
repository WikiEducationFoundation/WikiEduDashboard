require "#{Rails.root}/lib/importers/revision_importer"

#= Deletes duplicate Article records that differ by ID but match by title and namespace
class DuplicateArticleDeleter
  ###############
  # Entry point #
  ###############
  def self.resolve_duplicates(articles = nil)
    articles ||= Article.where(deleted: false)
    articles.group_by(&:wiki).each do |wiki, local_articles|
      titles = local_articles.map(&:title)
      # TODO: Relation group_by would eliminate array math
      grouped = Article.where(title: titles, wiki_id: wiki.id).group(%w(title namespace)).count
      page_ids = []
      grouped.each do |article|
        next unless article[1] > 1
        title = article[0][0]
        namespace = article[0][1]
        Rails.logger.debug "Resolving duplicates for '#{title}, ns #{namespace}'"
        page_ids |= delete_duplicates wiki, title, namespace
      end

      # At this stage check to see if the deleted articles' revisions still exist
      # if so, move them to their new article ID
      limbo_revisions = Revision.where(page_id: page_ids, wiki_id: wiki.id)
      RevisionImporter.move_or_delete_revisions limbo_revisions
    end
  end

  #################
  # Helper method #
  #################

  # Delete all articles with the given title
  # and namespace except for the most recently created
  def self.delete_duplicates(wiki, title, ns)
    articles = Article.where(title: title, namespace: ns, wiki_id: wiki.id).order(:created_at, :id)
    deleted = articles.where.not(mw_page_id: articles.last.mw_page_id)
    deleted.update_all(deleted: true)
    deleted.map(&:mw_page_id)
  end
end
