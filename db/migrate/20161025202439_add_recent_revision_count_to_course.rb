class AddRecentRevisionCountToCourse < ActiveRecord::Migration[5.0]
  def change
    add_column :courses, :recent_revision_count, :integer, default: 0
  end
end
