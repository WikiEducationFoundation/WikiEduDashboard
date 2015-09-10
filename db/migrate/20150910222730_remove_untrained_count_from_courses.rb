class RemoveUntrainedCountFromCourses < ActiveRecord::Migration
  def up
    remove_column :courses, :untrained_count
  end

  def down
    add_column :courses, :untrained_count, :integer, default: 0
  end
end
