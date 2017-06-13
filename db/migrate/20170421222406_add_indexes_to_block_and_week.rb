class AddIndexesToBlockAndWeek < ActiveRecord::Migration[5.0]
  def change
    add_index :weeks, :course_id
    add_index :blocks, :week_id
  end
end
