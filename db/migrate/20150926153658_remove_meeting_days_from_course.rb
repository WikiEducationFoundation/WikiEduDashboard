class RemoveMeetingDaysFromCourse < ActiveRecord::Migration[4.2]
  def up
    remove_column :courses, :meeting_days
  end

  def down
    add_column :courses, :meeting_days, :string
  end
end
