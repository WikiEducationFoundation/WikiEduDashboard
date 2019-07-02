class AddIndexToCoursesWikis < ActiveRecord::Migration[5.2]
  def change
    add_index :courses_wikis, :course_id
    add_index :courses_wikis, :wiki_id
    add_index :courses_wikis, [:course_id, :wiki_id], unique: true
  end
end
