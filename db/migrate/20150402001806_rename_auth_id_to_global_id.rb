class RenameAuthIdToGlobalId < ActiveRecord::Migration
  def change
    rename_column :users, :uid, :global_id
  end
end
