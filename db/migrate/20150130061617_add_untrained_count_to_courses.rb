class AddUntrainedCountToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :untrained_count, :integer, :default => 0
  end
end
