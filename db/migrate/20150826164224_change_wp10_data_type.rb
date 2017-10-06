class ChangeWp10DataType < ActiveRecord::Migration[4.2]
  def change
    change_column :revisions, :wp10, :float
    change_column :revisions, :wp10_previous, :float
  end
end
