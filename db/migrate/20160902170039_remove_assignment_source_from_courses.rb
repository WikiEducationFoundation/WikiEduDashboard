class RemoveAssignmentSourceFromCourses < ActiveRecord::Migration[4.2]
  def change
    remove_column :courses, :assignment_source
  end
end
