class ChangeBlockDueAndWeekStartColumns < ActiveRecord::Migration
  def change
    remove_column :weeks, :start, :date
    remove_column :blocks, :due_date, :date
    add_column :blocks, :duration, :integer, :default => 0
  end
end
