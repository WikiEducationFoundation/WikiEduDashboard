class AddTrainedCountToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :trained_count, :integer, default: 0
  end
end
