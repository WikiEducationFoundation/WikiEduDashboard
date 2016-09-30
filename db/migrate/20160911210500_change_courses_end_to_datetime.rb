class ChangeCoursesEndToDatetime < ActiveRecord::Migration
  def up
    change_column :courses, :end, :datetime
  end

  def down
    change_column :courses, :end, :date
  end
end
