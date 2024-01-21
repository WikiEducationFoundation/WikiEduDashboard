class CreateCourseNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :course_notes do |t|
      t.references :courses, foreign_key: true, type: :integer # Make sure to specify the type
      t.string :title
      t.text :text
      t.string :edited_by
      t.timestamps
    end
  end
end
