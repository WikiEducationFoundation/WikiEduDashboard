class IncreaseMaxCourseDayExceptionLength < ActiveRecord::Migration[4.2]
  def up
    change_column :courses, :day_exceptions, :string, limit: 2000
  end

  def down
    change_column :courses, :day_exceptions, :string, limit: 255
  end
end
