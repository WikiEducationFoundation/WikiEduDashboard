class CreateCategoriesCourses < ActiveRecord::Migration[5.1]
  def change
    create_table :categories_courses do |t|
      t.integer :category_id, index: true
      t.integer :course_id, index: true
      t.timestamps
    end
  end
end
