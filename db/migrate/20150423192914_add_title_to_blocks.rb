class AddTitleToBlocks < ActiveRecord::Migration[4.2]
  def change
    add_column :blocks, :title, :string
  end
end
