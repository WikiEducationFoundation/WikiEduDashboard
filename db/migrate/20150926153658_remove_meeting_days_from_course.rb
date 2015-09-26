class RemoveMeetingDaysFromCourse < ActiveRecord::Migration
  def up
    remove_column :courses, :meeting_days
  end

  def down
    add_column :courses, :meeting_days, :string
  end
end
