class ChangeCoursesTimelineEndToDatetime < ActiveRecord::Migration
  def up
    change_column :courses, :timeline_end, :datetime
    # FIXME: doesn't appear to work on the first run?
    Course.all.each do |course|
      course.update_attribute(:timeline_end, course.timeline_end.end_of_day)
    end
  end

  def down
    change_column :courses, :timeline_end, :date
  end
end
