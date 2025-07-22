class AddDueDateToBlocks < ActiveRecord::Migration[4.2]
  def change
    remove_column :blocks, :weekday
    add_column :blocks, :due_date, :date
  end
end
