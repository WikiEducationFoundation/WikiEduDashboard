class RenameBlockTypeColumn < ActiveRecord::Migration
  def change
    rename_column :blocks, :type, :kind
  end
end
