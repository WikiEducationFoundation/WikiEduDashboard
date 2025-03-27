class AddCompositeIndexToArticlesCourses < ActiveRecord::Migration[7.0]
  def change
    add_index :articles_courses, [:course_id, :article_id], name: "index_articles_courses_on_course_id_and_article_id"
  end
end