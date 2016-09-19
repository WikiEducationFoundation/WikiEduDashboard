class BackfillCoursesEndTimes < ActiveRecord::Migration
  def change
    Course.all.each do |course|
      course.update_attribute(:end, course.end.end_of_day)
    end
  end
end
