class ChangeGlobalIdToInt < ActiveRecord::Migration
  def change
    change_column :users, :global_id, :int
  end
end
