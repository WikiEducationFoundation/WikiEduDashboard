class AddTimelineStartDateToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :timeline_start, :date
    execute "UPDATE courses SET timeline_start = start"
  end

  def self.down
    remove_column :courses, :timeline_start
  end
end
