class RenameCourseIdOnGradeables < ActiveRecord::Migration[4.2]
  def change
    rename_column :gradeables, :course_id, :gradeable_item_id
  end
end
