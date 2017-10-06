class AddIndexToRevisions < ActiveRecord::Migration[4.2]
  def change
    add_index :revisions, [:article_id, :created_at]
  end
end
