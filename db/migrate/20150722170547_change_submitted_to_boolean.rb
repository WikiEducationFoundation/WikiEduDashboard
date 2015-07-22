class ChangeSubmittedToBoolean < ActiveRecord::Migration
  def self.up
    change_column :courses, :submitted, :boolean, default: false
  end

  def self.down
    change_column :courses, :submitted, :integer, default: false
  end
end
