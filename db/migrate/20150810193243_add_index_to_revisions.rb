class AddIndexToRevisions < ActiveRecord::Migration
  def change
    add_index :revisions, [:article_id, :created_at]
  end
end
