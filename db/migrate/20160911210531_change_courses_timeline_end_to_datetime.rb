class ChangeCoursesTimelineEndToDatetime < ActiveRecord::Migration
  def up
    change_column :courses, :timeline_end, :datetime
  end

  def down
    change_column :courses, :timeline_end, :date
  end
end
