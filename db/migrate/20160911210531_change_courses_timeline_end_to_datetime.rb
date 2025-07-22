class ChangeCoursesTimelineEndToDatetime < ActiveRecord::Migration[4.2]
  def up
    change_column :courses, :timeline_end, :datetime
  end

  def down
    change_column :courses, :timeline_end, :date
  end
end
