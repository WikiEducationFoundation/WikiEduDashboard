class UpdateBlockDurationDefault < ActiveRecord::Migration
  def self.up
    change_column_default :blocks, :duration, 1
    execute "UPDATE blocks SET duration = 1 WHERE duration = 0"
  end

  def self.down
    change_column_default :blocks, :duration, 03
  end
end
