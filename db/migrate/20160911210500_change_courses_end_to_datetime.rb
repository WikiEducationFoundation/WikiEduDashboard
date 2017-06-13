class ChangeCoursesEndToDatetime < ActiveRecord::Migration[4.2]
  def up
    change_column :courses, :end, :datetime
  end

  def down
    change_column :courses, :end, :date
  end
end
