class ChangeCoursesStartToDatetime < ActiveRecord::Migration[4.2]
  def up
    change_column :courses, :start, :datetime
  end

  def down
    change_column :courses, :start, :date
  end
end
