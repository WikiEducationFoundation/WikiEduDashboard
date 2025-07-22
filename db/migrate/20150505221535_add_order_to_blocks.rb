class AddOrderToBlocks < ActiveRecord::Migration[4.2]
  def change
    add_column :blocks, :order, :integer
  end
end
