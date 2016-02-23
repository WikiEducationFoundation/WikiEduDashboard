class DecoupleWikiIds < ActiveRecord::Migration
  def change
    add_column :articles, :native_id, :integer, index: true

    add_column :revisions, :native_id, :integer, index: true
    add_column :revisions, :page_id, :integer, index: true

    reversible do |dir|
      dir.up do
        Article.where(native_id: nil).update_all("native_id = id")

        Revision.where(native_id: nil).update_all("native_id = id")
        Revision.where(page_id: nil).update_all("page_id = article_id")
      end

      # NOTE: There's no safe way to downgrade this change, because primary IDs
      # will collide.
    end
  end
end
