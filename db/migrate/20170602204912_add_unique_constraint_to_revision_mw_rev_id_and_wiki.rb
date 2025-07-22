class AddUniqueConstraintToRevisionMwRevIdAndWiki < ActiveRecord::Migration[5.1]
  def change
    add_index :revisions, [:wiki_id, :mw_rev_id], unique: true
  end
end
