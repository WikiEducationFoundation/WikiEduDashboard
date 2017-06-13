class ChangeBlockDueDateToDate < ActiveRecord::Migration[4.2]
  def change
    change_column :blocks, :due_date, :date
  end
end
