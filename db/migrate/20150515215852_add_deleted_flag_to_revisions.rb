class AddDeletedFlagToRevisions < ActiveRecord::Migration[4.2]
  def change
    add_column :revisions, :deleted, :boolean, :default => false
  end
end
