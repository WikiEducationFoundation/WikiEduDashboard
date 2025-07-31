class AddCourseIdArticleIdUniqueIndexToArticlesCourses < ActiveRecord::Migration[7.0]
  def change
    add_index :articles_courses, [:course_id, :article_id], unique: true
  end
end
