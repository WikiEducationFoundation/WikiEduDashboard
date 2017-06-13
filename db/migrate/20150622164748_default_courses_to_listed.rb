class DefaultCoursesToListed < ActiveRecord::Migration[4.2]
  def self.up
    change_column_default :courses, :listed, true
  end

  def self.down
    change_column_default :courses, :listed, false
  end
end
