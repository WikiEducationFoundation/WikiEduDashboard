class AddOrderToWeeks < ActiveRecord::Migration[4.2]
  def change
    add_column :weeks, :order, :integer, null: false, default: 1
    Course.all.each do |course|
      course.weeks.each_with_index do |week, i|
        week.update_attribute(:order, i + 1)
      end
    end
  end
end
