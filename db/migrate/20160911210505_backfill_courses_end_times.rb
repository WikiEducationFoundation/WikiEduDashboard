class BackfillCoursesEndTimes < ActiveRecord::Migration[4.2]
  def change
    Course.all.each do |course|
      course.update_attribute(:end, course.end.end_of_day)
    end
  end
end
