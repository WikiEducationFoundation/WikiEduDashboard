class AddStartAndEndToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :start, :date
    add_column :courses, :end, :date
  end
end
