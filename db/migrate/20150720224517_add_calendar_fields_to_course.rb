class AddCalendarFieldsToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :day_exceptions, :string, :default => ''
    add_column :courses, :weekdays, :string, :default => '0000000'
  end
end
