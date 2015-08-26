class ChangeWp10DataType < ActiveRecord::Migration
  def change
    change_column :revisions, :wp10, :float
    change_column :revisions, :wp10_previous, :float
  end
end
