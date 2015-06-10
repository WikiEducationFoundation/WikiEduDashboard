class SetAutoIncrementOnCourseIds < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE courses AUTO_INCREMENT = 10000"
  end

  def self.down
    execute "ALTER TABLE courses AUTO_INCREMENT = 1"
  end
end
