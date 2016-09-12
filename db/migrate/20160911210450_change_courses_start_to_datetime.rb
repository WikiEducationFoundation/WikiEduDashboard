class ChangeCoursesStartToDatetime < ActiveRecord::Migration
  def up
    change_column :courses, :start, :datetime
  end

  def down
    change_column :courses, :start, :date
  end
end
