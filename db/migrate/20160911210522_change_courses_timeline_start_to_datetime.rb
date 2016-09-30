class ChangeCoursesTimelineStartToDatetime < ActiveRecord::Migration
  def up
    change_column :courses, :timeline_start, :datetime
  end

  def down
    change_column :courses, :timeline_start, :date
  end
end
