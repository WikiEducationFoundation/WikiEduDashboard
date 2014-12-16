class AddStartAndEndToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :start, :date
    add_column :courses, :end, :date
  end
end
