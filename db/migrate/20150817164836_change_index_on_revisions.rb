class ChangeIndexOnRevisions < ActiveRecord::Migration[4.2]
  def change
    remove_index :revisions, name: 'index_revisions_on_article_id_and_created_at'
    add_index :revisions, [:article_id, :date]
  end
end
