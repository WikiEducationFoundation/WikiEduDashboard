class ChangeSubmittedToBoolean < ActiveRecord::Migration[4.2]
  def self.up
    change_column :courses, :submitted, :boolean, default: false
  end

  def self.down
    change_column :courses, :submitted, :integer, default: false
  end
end
