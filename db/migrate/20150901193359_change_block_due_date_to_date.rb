class ChangeBlockDueDateToDate < ActiveRecord::Migration
  def change
    change_column :blocks, :due_date, :date
  end
end
