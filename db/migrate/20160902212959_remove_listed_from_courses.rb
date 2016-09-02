class RemoveListedFromCourses < ActiveRecord::Migration
  def change
    remove_column :courses, :listed
  end
end
