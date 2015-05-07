class AddDueDateToBlocks < ActiveRecord::Migration
  def change
    remove_column :blocks, :weekday
    add_column :blocks, :due_date, :date
  end
end
