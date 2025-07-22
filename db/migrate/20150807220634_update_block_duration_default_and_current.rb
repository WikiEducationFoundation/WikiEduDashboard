class UpdateBlockDurationDefaultAndCurrent < ActiveRecord::Migration[4.2]
  def self.up
    change_column_default :blocks, :duration, nil
    execute 'UPDATE blocks SET duration = NULL'
    rename_column :blocks, :duration, :due_date
    change_column :blocks, :due_date, :datetime
  end

  def self.down
    change_column :blocks, :due_date, :integer
    rename_column :blocks, :due_date, :duration
    change_column_default :blocks, :duration, 1
  end
end
