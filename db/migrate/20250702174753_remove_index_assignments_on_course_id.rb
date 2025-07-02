class RemoveIndexAssignmentsOnCourseId < ActiveRecord::Migration[7.0]
  def change
    remove_index :assignments, name: "index_assignments_on_course_id"
  end
end
