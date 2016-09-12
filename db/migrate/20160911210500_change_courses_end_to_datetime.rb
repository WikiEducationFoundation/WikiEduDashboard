class ChangeCoursesEndToDatetime < ActiveRecord::Migration
  def up
    change_column :courses, :end, :datetime
    Course.all.each do |course|
      course.update_attribute(:end, course.end.end_of_day)
    end
  end

  def down
    change_column :courses, :end, :date
  end
end
