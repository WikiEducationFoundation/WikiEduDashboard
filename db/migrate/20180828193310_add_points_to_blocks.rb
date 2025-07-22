class AddPointsToBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :blocks, :points, :integer
  end
end
