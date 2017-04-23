class RenameBlockTypeColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :blocks, :type, :kind
  end
end
