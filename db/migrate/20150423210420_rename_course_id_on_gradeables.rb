class RenameCourseIdOnGradeables < ActiveRecord::Migration
  def change
    rename_column :gradeables, :course_id, :gradeable_item_id
  end
end
