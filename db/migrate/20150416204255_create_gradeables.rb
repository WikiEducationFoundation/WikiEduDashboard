class CreateGradeables < ActiveRecord::Migration[4.2]
  def change
    create_table :gradeables do |t|
      t.string :title
      t.integer :points

      t.integer :course_id

      t.timestamps
    end
  end
end
