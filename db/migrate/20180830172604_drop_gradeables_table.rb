class DropGradeablesTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :gradeables
  end
end
