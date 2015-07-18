class AddTimelineEndToCourses < ActiveRecord::Migration
  def self.up
    add_column :courses, :timeline_end, :date
    execute "UPDATE courses SET timeline_end = end"
  end

  def self.down
    remove_column :courses, :timeline_end
  end
end
