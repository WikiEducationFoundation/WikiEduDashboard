class ChangeGlobalIdToInt < ActiveRecord::Migration[4.2]
  def change
    change_column :users, :global_id, :int
  end
end
