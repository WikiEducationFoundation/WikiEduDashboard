class ChangeCoursesTimelineStartToDatetime < ActiveRecord::Migration[4.2]
  def up
    change_column :courses, :timeline_start, :datetime
  end

  def down
    change_column :courses, :timeline_start, :date
  end
end
