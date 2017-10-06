class RenameAuthIdToGlobalId < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :uid, :global_id
  end
end
