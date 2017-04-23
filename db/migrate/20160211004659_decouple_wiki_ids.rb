class DecoupleWikiIds < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :mw_page_id, :integer, index: true

    add_column :revisions, :mw_rev_id, :integer, index: true
    add_column :revisions, :mw_page_id, :integer, index: true

    reversible do |dir|
      dir.up do
        Article.where(mw_page_id: nil).update_all("mw_page_id = id")

        Revision.where(mw_rev_id: nil).update_all("mw_rev_id = id")
        Revision.where(mw_page_id: nil).update_all("mw_page_id = article_id")
      end

      # NOTE: There's no safe way to downgrade this change, because primary IDs
      # will collide.
    end
  end
end
