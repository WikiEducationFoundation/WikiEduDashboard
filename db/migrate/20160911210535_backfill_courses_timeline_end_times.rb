class BackfillCoursesTimelineEndTimes < ActiveRecord::Migration
  def change
    Course.all.each do |course|
      course.update_attribute(:timeline_end, course.timeline_end.end_of_day)
    end
  end
end
