class RemoveAssignmentSourceFromCourses < ActiveRecord::Migration
  def change
    remove_column :courses, :assignment_source
  end
end
