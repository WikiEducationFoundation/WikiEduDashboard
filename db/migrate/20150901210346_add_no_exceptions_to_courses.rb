class AddNoExceptionsToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :no_day_exceptions, :boolean, default: false
    Course.where(weekdays: '000000').update_all(no_day_exceptions: true)
  end
end
