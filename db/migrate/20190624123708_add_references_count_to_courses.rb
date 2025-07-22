class AddReferencesCountToCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :references_count, :integer, default: 0
  end
end
