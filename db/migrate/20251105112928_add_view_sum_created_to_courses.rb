class AddViewSumCreatedToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :view_sum_created, :bigint, default: 0
  end
end

