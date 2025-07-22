class IndexCategoriesAndCategoriesCourses < ActiveRecord::Migration[5.1]
  def change
    add_index :categories, [:wiki_id, :name, :depth], unique: true
    add_index :categories_courses, [:course_id, :category_id], unique: true
  end
end
