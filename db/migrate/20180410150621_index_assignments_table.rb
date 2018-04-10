class IndexAssignmentsTable < ActiveRecord::Migration[5.1]
  def change
    add_index :assignments, [:course_id]
    add_index :assignments, [:course_id, :user_id]
  end
end
