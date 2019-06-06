class CreateCourseWikis < ActiveRecord::Migration[5.2]
  def change
    create_table :course_wikis do |t|
      t.integer :course_id, foreign_key: true
      t.integer :wiki_id, foreign_key: true
      t.timestamps
    end
  end
end
