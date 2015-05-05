class AddOrderToBlocks < ActiveRecord::Migration
  def change
    add_column :blocks, :order, :integer
  end
end
