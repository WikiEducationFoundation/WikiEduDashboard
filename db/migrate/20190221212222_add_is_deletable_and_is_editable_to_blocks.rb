class AddIsDeletableAndIsEditableToBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :blocks, :is_deletable, :boolean, default: true
    add_column :blocks, :is_editable, :boolean, default: true
  end
end
