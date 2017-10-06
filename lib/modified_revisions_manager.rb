# frozen_string_literal: true

require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/utils"

#= Updates records for revisions that were moved or deleted on Wikipedia
class ModifiedRevisionsManager
  def initialize(wiki)
    @wiki = wiki
  end

  def move_or_delete_revisions(revisions=nil)
    # NOTE: All revisions passed to this method should be from the same @wiki.
    revisions ||= Revision.where(wiki_id: @wiki.id)
    return if revisions.empty?

    synced_revisions = fetch_existing_revisions_from(revisions)
    synced_rev_ids = synced_revisions.map { |r| r['rev_id'].to_i }

    deleted_rev_ids = revisions.pluck(:mw_rev_id) - synced_rev_ids
    update_deleted_revisions(deleted_rev_ids)
    update_nondeleted_revisions(synced_rev_ids)

    moved_ids = synced_rev_ids - deleted_rev_ids
    update_moved_revisions(synced_revisions, moved_ids)
  end

  private

  def fetch_existing_revisions_from(revisions)
    Utils.chunk_requests(revisions, 100) do |block|
      Replica.new(@wiki).get_existing_revisions_by_id block
    end
  end

  def update_moved_revisions(synced_revisions, moved_ids)
    moved_revisions = synced_revisions.reduce([]) do |moved, rev|
      moved.push rev if moved_ids.include? rev['rev_id'].to_i
    end

    moved_revisions.each do |moved|
      handle_moved_revision moved
    end
  end

  def update_deleted_revisions(rev_ids)
    Revision.where(wiki_id: @wiki.id, mw_rev_id: rev_ids).update_all(deleted: true)
  end

  def update_nondeleted_revisions(rev_ids)
    Revision.where(wiki_id: @wiki.id, mw_rev_id: rev_ids).update_all(deleted: false)
  end

  def handle_moved_revision(moved)
    mw_page_id = moved['rev_page']

    unless Article.exists?(wiki_id: @wiki.id, mw_page_id: mw_page_id)
      ArticleImporter.new(@wiki).import_articles([mw_page_id])
    end

    article = Article.find_by(wiki_id: @wiki.id, mw_page_id: mw_page_id, deleted: false)

    # Don't update the revision to point to a new article if there isn't one.
    # This may happen if the article gets moved and then deleted, and there's
    # some inconsistency or timing delay in the update process.
    return unless article

    revision = Revision.find_by(wiki_id: @wiki.id, mw_rev_id: moved['rev_id'])
    return unless revision
    revision.update(article_id: article.id, mw_page_id: mw_page_id)
  end
end
