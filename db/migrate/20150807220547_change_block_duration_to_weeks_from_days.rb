class ChangeBlockDurationToWeeksFromDays < ActiveRecord::Migration[4.2]
  def self.up
    execute "UPDATE blocks SET duration = duration / 7"
  end

  def self.down
    execute "UPDATE blocks SET duration = duration * 7"
  end
end
