class AddTrainedCountToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :trained_count, :integer, default: 0
  end
end
