class AddDeletedFlagToRevisions < ActiveRecord::Migration
  def change
    add_column :revisions, :deleted, :boolean, :default => false
  end
end
