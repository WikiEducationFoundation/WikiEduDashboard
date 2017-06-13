class FixOrdersOnWeeks < ActiveRecord::Migration[4.2]
  def change
    Course.all.each do |course|
      next unless course.weeks.collect(&:order).uniq.count > 1
      course.reorder_weeks
    end
  end
end
