class RemoveListedFromCourses < ActiveRecord::Migration[4.2]
  def change
    remove_column :courses, :listed
  end
end
